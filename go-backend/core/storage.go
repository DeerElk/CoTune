package core

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"time"

	bolt "go.etcd.io/bbolt"
)

const (
	bucketTracks = "tracks" // trackID -> TrackMeta JSON
	bucketPeers  = "peers"  // peerid -> json addrs
)

type Storage struct {
	dbPath      string
	db          *bolt.DB
	storagePath string
}

func NewStorage(basePath string) (*Storage, error) {
	err := os.MkdirAll(basePath, 0o755)
	if err != nil {
		return nil, err
	}
	dbPath := filepath.Join(basePath, "cotune.db")
	db, err := bolt.Open(dbPath, 0o600, &bolt.Options{Timeout: 1 * time.Second})
	if err != nil {
		return nil, err
	}
	s := &Storage{dbPath: dbPath, db: db, storagePath: filepath.Join(basePath, "tracks")}
	// ensure buckets
	err = db.Update(func(tx *bolt.Tx) error {
		if _, e := tx.CreateBucketIfNotExists([]byte(bucketTracks)); e != nil {
			return e
		}
		if _, e := tx.CreateBucketIfNotExists([]byte(bucketPeers)); e != nil {
			return e
		}
		return nil
	})
	if err != nil {
		db.Close()
		return nil, err
	}
	if err := os.MkdirAll(s.storagePath, 0o755); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *Storage) Close() error {
	if s.db != nil {
		return s.db.Close()
	}
	return nil
}

func (s *Storage) SaveTrackMeta(m *TrackMeta) error {
	if m == nil || m.ID == "" {
		return errors.New("invalid track meta: empty id")
	}
	return s.db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketTracks))
		data, err := json.Marshal(m)
		if err != nil {
			return err
		}
		return b.Put([]byte(m.ID), data)
	})
}

func (s *Storage) MergeAndSaveTrackMeta(m *TrackMeta) error {
	if m == nil || m.ID == "" {
		return errors.New("invalid track meta: empty id")
	}
	// Merge with existing meta if present
	return s.db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketTracks))
		existingRaw := b.Get([]byte(m.ID))
		if existingRaw == nil {
			data, err := json.Marshal(m)
			if err != nil {
				return err
			}
			return b.Put([]byte(m.ID), data)
		}
		var exist TrackMeta
		if err := json.Unmarshal(existingRaw, &exist); err != nil {
			// fallback: overwrite
			data, err := json.Marshal(m)
			if err != nil {
				return err
			}
			return b.Put([]byte(m.ID), data)
		}
		merged := mergeTrackMeta(&exist, m)
		data, err := json.Marshal(merged)
		if err != nil {
			return err
		}
		return b.Put([]byte(m.ID), data)
	})
}

// mergeTrackMeta - deterministic merging rules:
// - If either Recognized==true, prefer the recognized record for Title/Artist.
// - Prefer non-empty Title/Artist; prefer larger Size for picking Path.
// - Owner is preserved if equal, else keep existing owner unless incoming has Recognized==true and existing is not recognized.
// - ProviderAddrs are unioned (unique).
func mergeTrackMeta(exist, incoming *TrackMeta) *TrackMeta {
	out := *exist // copy

	// Title/Artist: prefer recognized one or non-empty
	if incoming.Recognized && !exist.Recognized {
		if incoming.Title != "" {
			out.Title = incoming.Title
		}
		if incoming.Artist != "" {
			out.Artist = incoming.Artist
		}
		out.Recognized = true
	} else {
		if out.Title == "" && incoming.Title != "" {
			out.Title = incoming.Title
		}
		if out.Artist == "" && incoming.Artist != "" {
			out.Artist = incoming.Artist
		}
		// keep recognized flag if any is true
		if incoming.Recognized {
			out.Recognized = true
		}
	}

	// Path & Size: prefer larger size (likely higher bitrate) or recognized
	if incoming.Size > out.Size {
		out.Path = incoming.Path
		out.Size = incoming.Size
		out.Checksum = incoming.Checksum
		out.Owner = incoming.Owner
		out.Ts = incoming.Ts
	} else if out.Path == "" && incoming.Path != "" {
		out.Path = incoming.Path
		out.Size = incoming.Size
		out.Checksum = incoming.Checksum
		out.Owner = incoming.Owner
		out.Ts = incoming.Ts
	}

	// Merge provider addrs (unique)
	addrMap := map[string]struct{}{}
	for _, a := range out.ProviderAddrs {
		addrMap[a] = struct{}{}
	}
	for _, a := range incoming.ProviderAddrs {
		if a == "" {
			continue
		}
		if _, ok := addrMap[a]; !ok {
			out.ProviderAddrs = append(out.ProviderAddrs, a)
			addrMap[a] = struct{}{}
		}
	}

	// Ts: latest
	if incoming.Ts > out.Ts {
		out.Ts = incoming.Ts
	}
	// Checksum: prefer non-empty
	if out.Checksum == "" && incoming.Checksum != "" {
		out.Checksum = incoming.Checksum
	}
	return &out
}

func (s *Storage) DeleteTrack(id string) error {
	if id == "" {
		return errors.New("invalid id")
	}
	// Note: we only delete metadata. Physical file removal is not automatic to avoid accidental loss.
	return s.db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketTracks))
		return b.Delete([]byte(id))
	})
}

func (s *Storage) GetTrackMeta(id string) (*TrackMeta, error) {
	if id == "" {
		return nil, errors.New("invalid id")
	}
	var out TrackMeta
	err := s.db.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketTracks))
		v := b.Get([]byte(id))
		if v == nil {
			return errors.New("not found")
		}
		return json.Unmarshal(v, &out)
	})
	if err != nil {
		return nil, err
	}
	return &out, nil
}

func (s *Storage) AllTrackMetas() ([]*TrackMeta, error) {
	res := []*TrackMeta{}
	err := s.db.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketTracks))
		return b.ForEach(func(k, v []byte) error {
			var m TrackMeta
			if err := json.Unmarshal(v, &m); err != nil {
				// skip malformed
				return nil
			}
			res = append(res, &m)
			return nil
		})
	})
	if err != nil {
		return nil, err
	}
	return res, nil
}

func (s *Storage) SavePeerInfo(peerID string, addrs []string) error {
	if peerID == "" {
		return errors.New("invalid peer id")
	}
	return s.db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketPeers))
		// load existing
		existingRaw := b.Get([]byte(peerID))
		var existing []string
		if existingRaw != nil {
			_ = json.Unmarshal(existingRaw, &existing)
		}
		// union
		m := map[string]struct{}{}
		for _, a := range existing {
			if a != "" {
				m[a] = struct{}{}
			}
		}
		for _, a := range addrs {
			if a == "" {
				continue
			}
			if _, ok := m[a]; !ok {
				existing = append(existing, a)
				m[a] = struct{}{}
			}
		}
		data, err := json.Marshal(existing)
		if err != nil {
			return err
		}
		return b.Put([]byte(peerID), data)
	})
}

func (s *Storage) GetKnownPeers() (map[string][]string, error) {
	out := map[string][]string{}
	err := s.db.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(bucketPeers))
		return b.ForEach(func(k, v []byte) error {
			var a []string
			if err := json.Unmarshal(v, &a); err == nil {
				out[string(k)] = a
			}
			return nil
		})
	})
	return out, err
}

func (s *Storage) StoragePath() string {
	return s.storagePath
}

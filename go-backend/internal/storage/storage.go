package storage

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/cotune/go-backend/internal/models"
	"github.com/ipfs/go-datastore"
	"github.com/ipfs/go-datastore/query"
	badger "github.com/ipfs/go-ds-badger"
)

// Storage manages local track storage
type Storage struct {
	ds   *badger.Datastore
	mu   sync.RWMutex
	path string
}

// New creates a new storage instance
func New(dataDir string) (*Storage, error) {
	dsPath := filepath.Join(dataDir, "datastore")
	if err := os.MkdirAll(dsPath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create datastore dir: %w", err)
	}

	ds, err := badger.NewDatastore(dsPath, &badger.DefaultOptions)
	if err != nil {
		return nil, fmt.Errorf("failed to create datastore: %w", err)
	}

	return &Storage{
		ds:   ds,
		path: dataDir,
	}, nil
}

// SaveTrack saves a track to storage
func (s *Storage) SaveTrack(track *models.Track) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := datastore.NewKey(trackKey(track.ID))
	data, err := json.Marshal(track)
	if err != nil {
		return fmt.Errorf("failed to marshal track: %w", err)
	}

	if err := s.ds.Put(context.Background(), key, data); err != nil {
		return fmt.Errorf("failed to save track: %w", err)
	}

	return nil
}

// GetTrack retrieves a track by ID
func (s *Storage) GetTrack(id string) (*models.Track, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	key := datastore.NewKey(trackKey(id))
	data, err := s.ds.Get(context.Background(), key)
	if err != nil {
		return nil, fmt.Errorf("track not found: %w", err)
	}

	var track models.Track
	if err := json.Unmarshal(data, &track); err != nil {
		return nil, fmt.Errorf("failed to unmarshal track: %w", err)
	}

	return &track, nil
}

// GetAllTracks returns all tracks
func (s *Storage) GetAllTracks() ([]*models.Track, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	prefix := datastore.NewKey("/tracks/")
	q, err := s.ds.Query(context.Background(), query.Query{
		Prefix: prefix.String(),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to query: %w", err)
	}
	defer q.Close()

	var tracks []*models.Track
	for result := range q.Next() {
		if result.Error != nil {
			continue
		}

		var track models.Track
		if err := json.Unmarshal(result.Value, &track); err != nil {
			continue
		}

		tracks = append(tracks, &track)
	}

	return tracks, nil
}

// DeleteTrack deletes a track
func (s *Storage) DeleteTrack(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := datastore.NewKey(trackKey(id))
	return s.ds.Delete(context.Background(), key)
}

// FindTrackByCTID finds a track by CTID
func (s *Storage) FindTrackByCTID(ctid string) (*models.Track, error) {
	tracks, err := s.GetAllTracks()
	if err != nil {
		return nil, err
	}

	for _, track := range tracks {
		if track.CTID == ctid {
			return track, nil
		}
	}

	return nil, fmt.Errorf("track not found")
}

// FindTracksByToken finds tracks that match a token (local search)
func (s *Storage) FindTracksByToken(token string) ([]*models.Track, error) {
	tracks, err := s.GetAllTracks()
	if err != nil {
		return nil, err
	}

	tokenLower := toLower(token)
	var results []*models.Track

	for _, track := range tracks {
		if containsToken(track.Title, tokenLower) || containsToken(track.Artist, tokenLower) {
			results = append(results, track)
		}
	}

	return results, nil
}

// Close closes the storage
func (s *Storage) Close() error {
	return s.ds.Close()
}

func trackKey(id string) string {
	return fmt.Sprintf("/tracks/%s", id)
}

func toLower(s string) string {
	// Simple ASCII lowercase
	result := make([]byte, len(s))
	for i := 0; i < len(s); i++ {
		if s[i] >= 'A' && s[i] <= 'Z' {
			result[i] = s[i] + 32
		} else {
			result[i] = s[i]
		}
	}
	return string(result)
}

func containsToken(text, token string) bool {
	textLower := toLower(text)
	return len(textLower) >= len(token) &&
		(textLower == token ||
			contains(textLower, token))
}

func contains(s, substr string) bool {
	if len(substr) == 0 {
		return true
	}
	if len(substr) > len(s) {
		return false
	}
	for i := 0; i <= len(s)-len(substr); i++ {
		match := true
		for j := 0; j < len(substr); j++ {
			if s[i+j] != substr[j] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}

package search

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"time"

	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/protocol"
)

const (
	// IndexProtocol is the protocol ID for querying local indexes
	IndexProtocol = "/cotune/index/1.0.0"
)

// IndexQueryRequest represents a request to query a peer's local index
type IndexQueryRequest struct {
	Token string `json:"token"`
}

// IndexTrackHint carries metadata for a CTID from a remote peer.
type IndexTrackHint struct {
	CTID   string `json:"ctid"`
	Title  string `json:"title"`
	Artist string `json:"artist"`
}

// IndexQueryResponse represents a response with tracks for a token.
type IndexQueryResponse struct {
	Tracks []IndexTrackHint `json:"tracks"`
}

// QueryPeerIndex queries a peer's local index for a token and returns CTID hints.
func QueryPeerIndex(ctx context.Context, h host.Host, peerID peer.ID, token string) ([]IndexTrackHint, error) {
	// Connect if not connected
	if h.Network().Connectedness(peerID) != network.Connected {
		ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
		defer cancel()

		info := h.Peerstore().PeerInfo(peerID)
		if err := h.Connect(ctx, info); err != nil {
			return nil, fmt.Errorf("failed to connect to peer: %w", err)
		}
	}

	// Open stream
	stream, err := h.NewStream(ctx, peerID, protocol.ID(IndexProtocol))
	if err != nil {
		return nil, fmt.Errorf("failed to open stream: %w", err)
	}
	defer stream.Close()

	// Send request
	req := IndexQueryRequest{Token: token}
	if err := writeJSON(stream, req); err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}

	// Read response
	var resp IndexQueryResponse
	if err := readJSON(stream, &resp); err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	return resp.Tracks, nil
}

// HandleIndexQuery handles incoming index query requests
func (s *Service) HandleIndexQuery(stream network.Stream) {
	defer stream.Close()

	// Read request
	var req IndexQueryRequest
	if err := readJSON(stream, &req); err != nil {
		return
	}

	// Query local index
	s.mu.RLock()
	ctids := make([]string, 0)
	if localCTIDs, ok := s.localIndex[req.Token]; ok {
		ctids = append(ctids, localCTIDs...)
	}
	s.mu.RUnlock()

	// Fallback: rebuild candidates from persistent storage when in-memory index
	// is temporarily stale (e.g. after restarts).
	if len(ctids) == 0 {
		if tracks, err := s.store.FindTracksByToken(req.Token); err == nil {
			seen := make(map[string]struct{}, len(tracks))
			for _, tr := range tracks {
				if tr == nil || tr.CTID == "" || !tr.Recognized {
					continue
				}
				if _, ok := seen[tr.CTID]; ok {
					continue
				}
				seen[tr.CTID] = struct{}{}
				ctids = append(ctids, tr.CTID)
			}
		}
	}

	tracks := make([]IndexTrackHint, 0, len(ctids))
	for _, ctid := range ctids {
		hint := IndexTrackHint{
			CTID:   ctid,
			Title:  "Unknown",
			Artist: "Unknown",
		}
		if track, err := s.store.FindTrackByCTID(ctid); err == nil && track != nil {
			if track.Title != "" {
				hint.Title = track.Title
			}
			if track.Artist != "" {
				hint.Artist = track.Artist
			}
		}
		tracks = append(tracks, hint)
	}

	// Send response
	resp := IndexQueryResponse{
		Tracks: tracks,
	}
	writeJSON(stream, resp)
}

// RegisterIndexProtocol registers the index query protocol handler
func (s *Service) RegisterIndexProtocol(h host.Host) {
	h.SetStreamHandler(protocol.ID(IndexProtocol), s.HandleIndexQuery)
}

// Helper functions for JSON protocol
func readJSON(r io.Reader, v interface{}) error {
	var length uint32
	if err := readUint32(r, &length); err != nil {
		return err
	}
	if length > 10*1024*1024 { // 10MB max
		return fmt.Errorf("message too large: %d", length)
	}
	data := make([]byte, length)
	if _, err := io.ReadFull(r, data); err != nil {
		return err
	}
	return json.Unmarshal(data, v)
}

func writeJSON(w io.Writer, v interface{}) error {
	data, err := json.Marshal(v)
	if err != nil {
		return err
	}
	return writeMessage(w, data)
}

func writeMessage(w io.Writer, data []byte) error {
	if err := writeUint32(w, uint32(len(data))); err != nil {
		return err
	}
	_, err := w.Write(data)
	return err
}

func readUint32(r io.Reader, v *uint32) error {
	var buf [4]byte
	if _, err := io.ReadFull(r, buf[:]); err != nil {
		return err
	}
	*v = uint32(buf[0]) | uint32(buf[1])<<8 | uint32(buf[2])<<16 | uint32(buf[3])<<24
	return nil
}

func writeUint32(w io.Writer, v uint32) error {
	var buf [4]byte
	buf[0] = byte(v)
	buf[1] = byte(v >> 8)
	buf[2] = byte(v >> 16)
	buf[3] = byte(v >> 24)
	_, err := w.Write(buf[:])
	return err
}

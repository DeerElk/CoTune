package streaming

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"sync"
	"time"

	"github.com/cotune/go-backend/internal/storage"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/protocol"
)

const (
	// StreamingProtocol is the protocol ID for streaming
	StreamingProtocol = "/cotune/stream/1.0.0"
	// ChunkSize is the size of each chunk in bytes
	ChunkSize = 64 * 1024 // 64KB chunks
)

// Service handles streaming of audio files
type Service struct {
	h     host.Host
	store *storage.Storage
	mu    sync.RWMutex
}

// New creates a new streaming service
func New(h host.Host, store *storage.Storage) *Service {
	svc := &Service{
		h:     h,
		store: store,
	}

	// Register stream handler
	h.SetStreamHandler(protocol.ID(StreamingProtocol), svc.handleStream)

	return svc
}

// StreamRequest represents a streaming request
type StreamRequest struct {
	CTID string `json:"ctid"`
}

// StreamChunk represents a chunk of audio data
type StreamChunk struct {
	Index int    `json:"index"`
	Data  []byte `json:"data"`
	Total int    `json:"total"`
}

// handleStream handles incoming stream requests
func (s *Service) handleStream(stream network.Stream) {
	defer stream.Close()

	// Read request
	var req StreamRequest
	if err := readJSON(stream, &req); err != nil {
		return
	}

	// Find track by CTID
	track, err := s.store.FindTrackByCTID(req.CTID)
	if err != nil {
		// Track not found
		writeError(stream, fmt.Sprintf("track not found: %s", req.CTID))
		return
	}

	// Open file
	file, err := os.Open(track.Path)
	if err != nil {
		writeError(stream, fmt.Sprintf("failed to open file: %v", err))
		return
	}
	defer file.Close()

	// Get file size
	stat, err := file.Stat()
	if err != nil {
		writeError(stream, fmt.Sprintf("failed to stat file: %v", err))
		return
	}

	fileSize := stat.Size()
	totalChunks := int((fileSize + ChunkSize - 1) / ChunkSize)

	// Stream chunks
	buffer := make([]byte, ChunkSize)
	chunkIndex := 0

	for {
		n, err := file.Read(buffer)
		if err == io.EOF {
			break
		}
		if err != nil {
			writeError(stream, fmt.Sprintf("read error: %v", err))
			return
		}

		chunk := StreamChunk{
			Index: chunkIndex,
			Data:  buffer[:n],
			Total: totalChunks,
		}

		if err := writeJSON(stream, chunk); err != nil {
			return
		}

		chunkIndex++
	}
}

// StreamFromPeer streams a track from a peer
func (s *Service) StreamFromPeer(ctx context.Context, peerID peer.ID, ctid string, outputPath string) error {
	// Connect to peer if not connected
	if s.h.Network().Connectedness(peerID) != network.Connected {
		ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
		defer cancel()

		info := s.h.Peerstore().PeerInfo(peerID)
		if err := s.h.Connect(ctx, info); err != nil {
			return fmt.Errorf("failed to connect to peer: %w", err)
		}
	}

	// Open stream
	stream, err := s.h.NewStream(ctx, peerID, protocol.ID(StreamingProtocol))
	if err != nil {
		return fmt.Errorf("failed to open stream: %w", err)
	}
	defer stream.Close()

	// Send request
	req := StreamRequest{CTID: ctid}
	if err := writeJSON(stream, req); err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}

	// Create output file
	outFile, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("failed to create output file: %w", err)
	}
	defer outFile.Close()

	// Receive chunks
	for {
		var chunk StreamChunk
		if err := readJSON(stream, &chunk); err != nil {
			if err == io.EOF {
				break
			}
			return fmt.Errorf("failed to read chunk: %w", err)
		}

		// Check for error response
		if chunk.Index == -1 && len(chunk.Data) > 0 {
			return fmt.Errorf("stream error: %s", string(chunk.Data))
		}

		// Write chunk to file
		if _, err := outFile.Write(chunk.Data); err != nil {
			return fmt.Errorf("failed to write chunk: %w", err)
		}

		// Last chunk
		if chunk.Index >= chunk.Total-1 {
			break
		}
	}

	return nil
}

// Helper functions for simple binary protocol
// Format: [4 bytes length][data]
func readMessage(r io.Reader) ([]byte, error) {
	var length uint32
	if err := readUint32(r, &length); err != nil {
		return nil, err
	}
	if length > 10*1024*1024 { // 10MB max
		return nil, fmt.Errorf("message too large: %d", length)
	}
	data := make([]byte, length)
	if _, err := io.ReadFull(r, data); err != nil {
		return nil, err
	}
	return data, nil
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

func readJSON(r io.Reader, v interface{}) error {
	data, err := readMessage(r)
	if err != nil {
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

func writeError(w io.Writer, msg string) {
	chunk := StreamChunk{
		Index: -1,
		Data:  []byte(msg),
		Total: 0,
	}
	writeJSON(w, chunk)
}

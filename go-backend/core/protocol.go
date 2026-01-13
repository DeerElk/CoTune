package core

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"time"

	network "github.com/libp2p/go-libp2p/core/network"
	peer "github.com/libp2p/go-libp2p/core/peer"
)

const FileProtocolID = "/cotune/file/1.0.0"
const MetaProtocolID = "/cotune/meta/1.0.0"
const MaxFetchSize = 350 << 20 // 350 MiB

// Stream handler: receive request JSON like {"id":"trackid"}\n and then respond
// with header JSON {"id":..,"size":..,"checksum":..}\n then raw bytes of file.
func (n *CotuneNode) handleFileStream(s network.Stream) {
	defer s.Close()
	r := bufio.NewReader(s)
	line, err := r.ReadBytes('\n')
	if err != nil {
		// nothing to do
		return
	}
	var req struct {
		ID string `json:"id"`
	}
	if err := jsonUnmarshal(line, &req); err != nil {
		_ = writeJSONThenClose(s, map[string]any{"error": "bad request"})
		return
	}
	if req.ID == "" {
		_ = writeJSONThenClose(s, map[string]any{"error": "missing id"})
		return
	}
	meta, err := n.storage.GetTrackMeta(req.ID)
	if err != nil {
		_ = writeJSONThenClose(s, map[string]any{"error": "not found"})
		return
	}
	// open file and check size BEFORE sending header
	f, err := os.Open(meta.Path)
	if err != nil {
		_ = writeJSONThenClose(s, map[string]any{"error": "no file"})
		return
	}
	defer f.Close()
	stat, err := f.Stat()
	if err != nil {
		_ = writeJSONThenClose(s, map[string]any{"error": "file stat error"})
		return
	}
	// server-side size protection: refuse to serve files larger than MaxFetchSize
	if stat.Size() > MaxFetchSize {
		_ = writeJSONThenClose(s, map[string]any{"error": "file too large"})
		return
	}

	header := map[string]any{
		"id":       meta.ID,
		"size":     stat.Size(),
		"checksum": meta.Checksum,
	}
	enc := json.NewEncoder(s)
	if err := enc.Encode(header); err != nil {
		return
	}
	// now stream raw bytes. do not write additional newlines (client reads header up to newline).
	_, _ = io.Copy(s, f)
}

// helper to write JSON error and close
func writeJSONThenClose(s network.Stream, v any) error {
	enc := json.NewEncoder(s)
	_ = enc.Encode(v)
	_ = s.Close()
	return nil
}

// Client fetch: open stream to peer and request track id, save to local path and return path
func (n *CotuneNode) FetchFromPeer(pid string, trackID string) (string, error) {
	if n.Host == nil {
		return "", fmt.Errorf("host not started")
	}
	p, err := peer.Decode(pid)
	if err != nil {
		return "", err
	}
	// gather addresses: peerstore -> cached providers -> DHT fallback
	addrs := n.Host.Peerstore().Addrs(p)
	if len(addrs) == 0 {
		for _, pi := range n.cachedProvidersFromStorage(trackID) {
			if pi.ID == p {
				addrs = append(addrs, pi.Addrs...)
			}
		}
	}
	if len(addrs) == 0 && n.DHT != nil {
		provs, _ := n.FindProviders(trackID, 10)
		for _, pi := range provs {
			if pi.ID == p {
				addrs = append(addrs, pi.Addrs...)
			}
		}
	}

	// add to peerstore if we have addrs
	if len(addrs) > 0 {
		n.Host.Peerstore().AddAddrs(p, addrs, time.Hour)
		ctxDial, cancelDial := context.WithTimeout(n.ctx, 10*time.Second)
		defer cancelDial()
		_ = n.Host.Connect(ctxDial, peer.AddrInfo{ID: p, Addrs: addrs})
	}

	// open stream
	ctx, cancel := context.WithTimeout(n.ctx, 30*time.Second)
	defer cancel()
	s, err := n.Host.NewStream(ctx, p, FileProtocolID)
	if err != nil {
		return "", err
	}
	defer s.Close()
	// send request
	req := map[string]string{"id": trackID}
	if err := json.NewEncoder(s).Encode(req); err != nil {
		return "", err
	}
	// read header
	r := bufio.NewReader(s)
	headerLine, err := r.ReadBytes('\n')
	if err != nil {
		return "", err
	}
	var header map[string]any
	if err := jsonUnmarshal(headerLine, &header); err != nil {
		return "", err
	}
	if errVal, ok := header["error"]; ok {
		return "", fmt.Errorf("remote error: %v", errVal)
	}
	size := int64(0)
	if v, ok := header["size"].(float64); ok {
		size = int64(v)
	}

	// --- BEG: безопасное создание файла и ограниченное чтение ---
	if size > 0 && size > MaxFetchSize {
		return "", fmt.Errorf("remote reported too large file: %d bytes", size)
	}

	// prepare target file
	targetDir := n.storage.StoragePath()
	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return "", err
	}
	safeName := fmt.Sprintf("%s_%d", trackID, time.Now().UnixNano())
	targetPath := filepath.Join(targetDir, safeName+".dat")
	tmp, err := os.Create(targetPath)
	if err != nil {
		return "", err
	}
	// ensure file closed at function exit
	defer func() { _ = tmp.Close() }()

	// copy raw bytes с лимитом (MaxFetchSize+1 чтобы поймать превышение)
	lr := io.LimitReader(r, MaxFetchSize+1)
	written, err := io.Copy(tmp, lr)
	if err != nil {
		_ = os.Remove(targetPath)
		return "", err
	}
	if written > MaxFetchSize {
		_ = os.Remove(targetPath)
		return "", fmt.Errorf("fetched file too large")
	}
	// --- END безопасного блока ---

	// best-effort size check
	if size > 0 && written != size {
		log.Printf("FetchFromPeer: size mismatch for %s expected %d got %d", trackID, size, written)
	}
	// interpret checksum if present
	checksum := ""
	if cs, ok := header["checksum"].(string); ok {
		checksum = cs
	} else if header["checksum"] != nil {
		// fallback to fmt.Sprintf if non-string present
		checksum = fmt.Sprintf("%v", header["checksum"])
	}

	// create a local TrackMeta and save (owner is pid)
	meta := &TrackMeta{
		ID:         trackID,
		Title:      trackID,
		Artist:     "Unknown",
		Owner:      pid,
		Path:       targetPath,
		Recognized: true,
		Checksum:   checksum,
		Size:       written,
		Ts:         nowMillis(),
	}
	_ = n.storage.MergeAndSaveTrackMeta(meta)
	return targetPath, nil
}

// Stream handler for metadata requests: receive request JSON like {"id":"trackid"}\n and respond with TrackMeta JSON
func (n *CotuneNode) handleMetaStream(s network.Stream) {
	defer s.Close()
	r := bufio.NewReader(s)
	line, err := r.ReadBytes('\n')
	if err != nil {
		return
	}
	var req struct {
		ID string `json:"id"`
	}
	if err := jsonUnmarshal(line, &req); err != nil {
		_ = writeJSONThenClose(s, map[string]any{"error": "bad request"})
		return
	}
	if req.ID == "" {
		_ = writeJSONThenClose(s, map[string]any{"error": "missing id"})
		return
	}
	meta, err := n.storage.GetTrackMeta(req.ID)
	if err != nil {
		_ = writeJSONThenClose(s, map[string]any{"error": "not found"})
		return
	}
	enc := json.NewEncoder(s)
	_ = enc.Encode(meta)
}

// GetTrackMetaFromPeer requests track metadata from a peer via DHT first, then stream protocol as fallback
func (n *CotuneNode) GetTrackMetaFromPeer(pid string, trackID string) (*TrackMeta, error) {
	if n.Host == nil {
		return nil, fmt.Errorf("host not started")
	}
	// Note: DHT PutValue/GetValue requires record validator setup, which is complex.
	// We rely on PubSub for metadata distribution and stream protocol for retrieval.
	// Fallback to stream protocol (requires connection)
	p, err := peer.Decode(pid)
	if err != nil {
		return nil, err
	}
	// gather addresses
	addrs := n.Host.Peerstore().Addrs(p)
	if len(addrs) == 0 {
		provs, _ := n.FindProviders(trackID, 10)
		for _, pi := range provs {
			if pi.ID == p {
				addrs = append(addrs, pi.Addrs...)
			}
		}
	}
	if len(addrs) > 0 {
		n.Host.Peerstore().AddAddrs(p, addrs, time.Hour)
		ctxDial, cancelDial := context.WithTimeout(n.ctx, 10*time.Second)
		defer cancelDial()
		_ = n.Host.Connect(ctxDial, peer.AddrInfo{ID: p, Addrs: addrs})
	}
	// open stream
	ctx, cancel := context.WithTimeout(n.ctx, 10*time.Second)
	defer cancel()
	s, err := n.Host.NewStream(ctx, p, MetaProtocolID)
	if err != nil {
		return nil, err
	}
	defer s.Close()
	// send request
	req := map[string]string{"id": trackID}
	if err := json.NewEncoder(s).Encode(req); err != nil {
		return nil, err
	}
	// read response
	r := bufio.NewReader(s)
	responseLine, err := r.ReadBytes('\n')
	if err != nil {
		return nil, err
	}
	var response map[string]any
	if err := jsonUnmarshal(responseLine, &response); err != nil {
		return nil, err
	}
	if errVal, ok := response["error"]; ok {
		return nil, fmt.Errorf("remote error: %v", errVal)
	}
	// parse TrackMeta
	var meta TrackMeta
	metaBytes, _ := json.Marshal(response)
	if err := jsonUnmarshal(metaBytes, &meta); err != nil {
		return nil, err
	}
	return &meta, nil
}

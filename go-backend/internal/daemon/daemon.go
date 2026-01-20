package daemon

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/cotune/go-backend/internal/ctr"
	"github.com/cotune/go-backend/internal/dht"
	"github.com/cotune/go-backend/internal/host"
	"github.com/cotune/go-backend/internal/models"
	"github.com/cotune/go-backend/internal/search"
	"github.com/cotune/go-backend/internal/storage"
	"github.com/cotune/go-backend/internal/streaming"
	libp2phost "github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/peer"
)

// Daemon is the main daemon that coordinates all services
type Daemon struct {
	h              libp2phost.Host
	dht            *dht.Service
	ctr            *ctr.Service
	search         *search.Service
	streaming      *streaming.Service
	store          *storage.Storage
	mu             sync.RWMutex
	running        bool
	announceTicker *time.Ticker
	ctx            context.Context
	cancel         context.CancelFunc
}

// New creates a new daemon
func New(
	h libp2phost.Host,
	dhtService *dht.Service,
	ctrService *ctr.Service,
	searchService *search.Service,
	streamingService *streaming.Service,
	store *storage.Storage,
) *Daemon {
	ctx, cancel := context.WithCancel(context.Background())

	return &Daemon{
		h:         h,
		dht:       dhtService,
		ctr:       ctrService,
		search:    searchService,
		streaming: streamingService,
		store:     store,
		ctx:       ctx,
		cancel:    cancel,
	}
}

// Start starts the daemon
func (d *Daemon) Start(ctx context.Context) error {
	d.mu.Lock()
	if d.running {
		d.mu.Unlock()
		return fmt.Errorf("daemon already running")
	}
	d.running = true
	d.mu.Unlock()

	// Start CTR service
	d.ctr.Start()

	// Start periodic announce
	d.announceTicker = time.NewTicker(4 * time.Minute)
	go d.announceLoop()

	// Initial announce
	go func() {
		time.Sleep(5 * time.Second)
		d.announceAllTracks(context.Background())
	}()

	return nil
}

// Stop stops the daemon
func (d *Daemon) Stop(ctx context.Context) error {
	d.mu.Lock()
	if !d.running {
		d.mu.Unlock()
		return nil
	}
	d.running = false
	d.mu.Unlock()

	d.cancel()

	if d.announceTicker != nil {
		d.announceTicker.Stop()
	}

	// Stop CTR service
	if err := d.ctr.Stop(ctx); err != nil {
		return fmt.Errorf("failed to stop CTR: %w", err)
	}

	return nil
}

// announceLoop periodically announces all recognized tracks
func (d *Daemon) announceLoop() {
	for {
		select {
		case <-d.ctx.Done():
			return
		case <-d.announceTicker.C:
			d.announceAllTracks(d.ctx)
		}
	}
}

// announceAllTracks announces all recognized tracks in DHT
func (d *Daemon) announceAllTracks(ctx context.Context) {
	tracks, err := d.store.GetAllTracks()
	if err != nil {
		return
	}

	for _, track := range tracks {
		if !track.Recognized || track.CTID == "" {
			continue
		}

		// Announce CTID in DHT
		if err := d.dht.Provide(ctx, track.CTID); err != nil {
			// Non-fatal, continue
			continue
		}

		// Announce tokens in DHT (for search)
		tokens := d.search.Tokenize(track.Title + " " + track.Artist)
		for _, token := range tokens {
			tokenHash := dht.HashToken(token)
			if err := d.dht.ProvideToken(ctx, tokenHash); err != nil {
				// Non-fatal, continue
				continue
			}
		}
	}
}

// ShareTrack shares a track (announces it in DHT)
func (d *Daemon) ShareTrack(ctx context.Context, trackID string) error {
	track, err := d.store.GetTrack(trackID)
	if err != nil {
		return fmt.Errorf("track not found: %w", err)
	}

	if track.CTID == "" {
		return fmt.Errorf("track has no CTID (not processed yet)")
	}

	if !track.Recognized {
		return fmt.Errorf("track not recognized (user must enter title/artist)")
	}

	// Announce CTID in DHT
	if err := d.dht.Provide(ctx, track.CTID); err != nil {
		return fmt.Errorf("failed to provide CTID in DHT: %w", err)
	}

	// Announce tokens in DHT (for search)
	tokens := d.search.Tokenize(track.Title + " " + track.Artist)
	for _, token := range tokens {
		tokenHash := dht.HashToken(token)
		if err := d.dht.ProvideToken(ctx, tokenHash); err != nil {
			// Non-fatal, continue
			continue
		}
	}

	// Update local search index
	d.search.UpdateLocalIndex(track)

	return nil
}

// Search performs a search
func (d *Daemon) Search(ctx context.Context, query string, maxResults int) ([]*search.SearchResult, error) {
	return d.search.Search(ctx, query, maxResults)
}

// FindProviders finds providers for a CTID
func (d *Daemon) FindProviders(ctx context.Context, ctid string, max int) ([]peer.AddrInfo, error) {
	return d.dht.FindProviders(ctx, ctid, max)
}

// FetchTrack fetches a track from the network
func (d *Daemon) FetchTrack(ctx context.Context, ctid string, outputPath string) error {
	// Find providers
	providers, err := d.dht.FindProviders(ctx, ctid, 12)
	if err != nil {
		return fmt.Errorf("failed to find providers: %w", err)
	}

	if len(providers) == 0 {
		return fmt.Errorf("no providers found for CTID: %s", ctid)
	}

	// Try each provider
	var lastErr error
	for _, provider := range providers {
		err := d.streaming.StreamFromPeer(ctx, provider.ID, ctid, outputPath)
		if err == nil {
			return nil
		}
		lastErr = err
	}

	return fmt.Errorf("failed to fetch from all providers: %w", lastErr)
}

// AddTrack adds a new track (copies file and processes)
func (d *Daemon) AddTrack(ctx context.Context, sourcePath string, title string, artist string) (*models.Track, error) {
	// Generate track ID
	trackID := generateTrackID()

	// Copy file to storage
	destPath, err := d.copyTrackFile(trackID, sourcePath)
	if err != nil {
		return nil, fmt.Errorf("failed to copy file: %w", err)
	}

	// Create track
	track := &models.Track{
		ID:         trackID,
		Title:      title,
		Artist:     artist,
		Path:       destPath,
		Liked:      false,
		Recognized: title != "" && artist != "",
	}

	// Save track
	if err := d.store.SaveTrack(track); err != nil {
		return nil, fmt.Errorf("failed to save track: %w", err)
	}

	// Queue for CTR processing
	d.ctr.QueueTrack(track)

	return track, nil
}

// ProcessTrack processes a track (computes CTID)
func (d *Daemon) ProcessTrack(ctx context.Context, trackID string) error {
	track, err := d.store.GetTrack(trackID)
	if err != nil {
		return fmt.Errorf("track not found: %w", err)
	}

	return d.ctr.ProcessTrack(ctx, track)
}

// GetPeerInfo returns peer information
func (d *Daemon) GetPeerInfo() map[string]interface{} {
	addrs := make([]string, 0)
	for _, addr := range d.h.Addrs() {
		addrStr := fmt.Sprintf("%s/p2p/%s", addr.String(), d.h.ID().String())
		addrs = append(addrs, addrStr)
	}

	// Get relay addresses
	relays := d.GetRelayAddresses()

	return map[string]interface{}{
		"peerId": d.h.ID().String(),
		"addrs":  addrs,
		"relays": relays,
		"pubkey": d.h.ID().String(), // Simplified
	}
}

// GetKnownPeers returns list of known peers
func (d *Daemon) GetKnownPeers() []string {
	peers := d.h.Network().Peers()
	result := make([]string, 0, len(peers))
	for _, peerID := range peers {
		addrs := d.h.Peerstore().Addrs(peerID)
		if len(addrs) > 0 {
			addrStr := fmt.Sprintf("%s/p2p/%s", addrs[0].String(), peerID.String())
			result = append(result, addrStr)
		} else {
			result = append(result, peerID.String())
		}
	}
	return result
}

// ConnectToPeer connects to a peer by multiaddr string
func (d *Daemon) ConnectToPeer(ctx context.Context, addrStr string) error {
	return host.ConnectToPeer(ctx, d.h, addrStr)
}

// ConnectToPeerInfo connects to a peer using peer ID and addresses
func (d *Daemon) ConnectToPeerInfo(ctx context.Context, peerID string, addrs []string) error {
	return host.ConnectToPeerInfo(ctx, d.h, peerID, addrs)
}

// FetchTrackFromPeer fetches a track from a specific peer
func (d *Daemon) FetchTrackFromPeer(ctx context.Context, peerID peer.ID, ctid string, outputPath string) error {
	return d.streaming.StreamFromPeer(ctx, peerID, ctid, outputPath)
}

// GetRelayAddresses returns relay addresses for this peer
func (d *Daemon) GetRelayAddresses() []string {
	relays := make([]string, 0)

	// Get circuit addresses from peerstore
	peers := d.h.Network().Peers()
	for _, peerID := range peers {
		addrs := d.h.Peerstore().Addrs(peerID)
		for _, addr := range addrs {
			addrStr := addr.String()
			// Check if it's a relay address
			if contains(addrStr, "/p2p-circuit/") {
				relayAddr := fmt.Sprintf("%s/p2p/%s", addrStr, peerID.String())
				relays = append(relays, relayAddr)
			}
		}
	}

	return relays
}

// EnableRelay enables relay service (already enabled in host setup)
func (d *Daemon) EnableRelay() error {
	// Relay is already enabled in host.New if enableRelay flag is set
	// This is a no-op for now, but can be extended if needed
	return nil
}

// RequestRelayConnection requests a relay connection to a target peer
func (d *Daemon) RequestRelayConnection(ctx context.Context, targetPeerID string) (string, error) {
	// Find providers that might be relays
	// In a full implementation, we'd query the DHT for relay nodes
	// For now, return empty string
	return "", fmt.Errorf("relay request not fully implemented")
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr ||
		(len(s) > len(substr) &&
			(s[:len(substr)] == substr ||
				s[len(s)-len(substr):] == substr ||
				findSubstring(s, substr))))
}

func findSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// Helper functions
func generateTrackID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

func (d *Daemon) copyTrackFile(trackID string, sourcePath string) (string, error) {
	// Determine storage directory
	storageDir := filepath.Join(filepath.Dir(sourcePath), "cotune_tracks")
	if err := os.MkdirAll(storageDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create storage dir: %w", err)
	}

	// Determine destination path
	ext := filepath.Ext(sourcePath)
	destPath := filepath.Join(storageDir, trackID+ext)

	// Copy file
	source, err := os.Open(sourcePath)
	if err != nil {
		return "", fmt.Errorf("failed to open source: %w", err)
	}
	defer source.Close()

	dest, err := os.Create(destPath)
	if err != nil {
		return "", fmt.Errorf("failed to create dest: %w", err)
	}
	defer dest.Close()

	if _, err := io.Copy(dest, source); err != nil {
		return "", fmt.Errorf("failed to copy: %w", err)
	}

	return destPath, nil
}

package ctr

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"sync"
	"time"

	"github.com/cotune/go-backend/internal/audio"
	"github.com/cotune/go-backend/internal/dht"
	"github.com/cotune/go-backend/internal/models"
	"github.com/cotune/go-backend/internal/storage"
)

// Service handles Canonical Track Resolution
type Service struct {
	store   *storage.Storage
	dht     *dht.Service
	queue   chan *models.Track
	workers int
	wg      sync.WaitGroup
	mu      sync.RWMutex
	running bool
	ctx     context.Context
	cancel  context.CancelFunc
	// onProcessed is called after successful processing and save.
	onProcessed func(context.Context, *models.Track)
}

// New creates a new CTR service
func New(store *storage.Storage, dhtService *dht.Service) *Service {
	ctx, cancel := context.WithCancel(context.Background())

	return &Service{
		store:   store,
		dht:     dhtService,
		queue:   make(chan *models.Track, 100),
		workers: 2, // Process 2 tracks concurrently
		ctx:     ctx,
		cancel:  cancel,
	}
}

// Start starts the CTR workers
func (s *Service) Start() {
	s.mu.Lock()
	if s.running {
		s.mu.Unlock()
		return
	}
	s.running = true
	s.mu.Unlock()

	for i := 0; i < s.workers; i++ {
		s.wg.Add(1)
		go s.worker()
	}
}

// Stop stops the CTR service
func (s *Service) Stop(ctx context.Context) error {
	s.mu.Lock()
	if !s.running {
		s.mu.Unlock()
		return nil
	}
	s.running = false
	s.mu.Unlock()

	s.cancel()

	// Wait for workers with timeout
	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// QueueTrack queues a track for CTR processing
func (s *Service) QueueTrack(track *models.Track) {
	s.mu.RLock()
	running := s.running
	s.mu.RUnlock()

	if !running {
		return
	}

	select {
	case s.queue <- track:
	default:
		// Queue full, skip
	}
}

// ProcessTrack processes a track immediately (synchronous)
func (s *Service) ProcessTrack(ctx context.Context, track *models.Track) error {
	ctid, err := s.computeCTID(ctx, track.Path)
	if err != nil {
		return fmt.Errorf("failed to compute CTID: %w", err)
	}

	track.CTID = ctid

	// Save updated track
	if err := s.store.SaveTrack(track); err != nil {
		return fmt.Errorf("failed to save track: %w", err)
	}

	// If recognized, announce in DHT
	if track.Recognized {
		if err := s.dht.Provide(ctx, ctid); err != nil {
			// Non-fatal, log and continue
			fmt.Printf("Failed to provide CTID in DHT: %v\n", err)
		}
	}

	s.mu.RLock()
	onProcessed := s.onProcessed
	s.mu.RUnlock()
	if onProcessed != nil {
		onProcessed(ctx, track)
	}

	return nil
}

// SetOnProcessed sets a callback triggered after successful ProcessTrack.
func (s *Service) SetOnProcessed(fn func(context.Context, *models.Track)) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.onProcessed = fn
}

func (s *Service) worker() {
	defer s.wg.Done()

	for {
		select {
		case <-s.ctx.Done():
			return
		case track := <-s.queue:
			ctx, cancel := context.WithTimeout(s.ctx, 5*time.Minute)
			if err := s.ProcessTrack(ctx, track); err != nil {
				fmt.Printf("CTR processing error: %v\n", err)
			}
			cancel()
		}
	}
}

// computeCTID computes the Canonical Track ID from an audio file
func (s *Service) computeCTID(ctx context.Context, filePath string) (string, error) {
	// Decode audio to PCM
	pcm, err := audio.DecodeAudioToPCM(ctx, filePath)
	if err != nil {
		return "", fmt.Errorf("failed to decode audio: %w", err)
	}

	// Normalize PCM
	normalized := normalizePCM(pcm)

	// Compute SHA256
	hash := sha256.Sum256(normalized)
	return hex.EncodeToString(hash[:]), nil
}

// normalizePCM normalizes PCM audio data
func normalizePCM(pcm []int16) []byte {
	if len(pcm) == 0 {
		return []byte{}
	}

	// Convert to bytes (little-endian)
	result := make([]byte, len(pcm)*2)
	for i, sample := range pcm {
		result[i*2] = byte(sample)
		result[i*2+1] = byte(sample >> 8)
	}

	return result
}

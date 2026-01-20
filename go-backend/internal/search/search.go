package search

import (
	"context"
	"fmt"
	"strings"
	"sync"

	"github.com/libp2p/go-libp2p/core/host"

	"github.com/cotune/go-backend/internal/dht"
	dhtpkg "github.com/cotune/go-backend/internal/dht"
	"github.com/cotune/go-backend/internal/models"
	"github.com/cotune/go-backend/internal/storage"
)

// Service handles search functionality
type Service struct {
	store *storage.Storage
	dht   *dht.Service
	host  host.Host
	mu    sync.RWMutex
	// Local index: token -> []CTID
	localIndex map[string][]string
}

// New creates a new search service
func New(store *storage.Storage, dhtService *dht.Service, h host.Host) *Service {
	svc := &Service{
		store:      store,
		dht:        dhtService,
		host:       h,
		localIndex: make(map[string][]string),
	}
	// Register index protocol handler
	svc.RegisterIndexProtocol(h)
	return svc
}

// SearchResult represents a search result
type SearchResult struct {
	CTID       string   `json:"ctid"`
	Title      string   `json:"title"`
	Artist     string   `json:"artist"`
	Recognized bool     `json:"recognized"`
	Providers  []string `json:"providers"` // Peer IDs that can provide this track
}

// Search performs a search query
func (s *Service) Search(ctx context.Context, query string, maxResults int) ([]*SearchResult, error) {
	// Tokenize query
	tokens := s.tokenize(query)
	if len(tokens) == 0 {
		return []*SearchResult{}, nil
	}

	// First, search locally
	localResults := s.searchLocal(tokens)

	// Then, search in network
	networkResults, err := s.searchNetwork(ctx, tokens, maxResults)
	if err != nil {
		// Non-fatal, continue with local results
		fmt.Printf("Network search error: %v\n", err)
	}

	// Merge results
	seenCTIDs := make(map[string]bool)
	var results []*SearchResult

	// Add local results first
	for _, result := range localResults {
		if !seenCTIDs[result.CTID] {
			seenCTIDs[result.CTID] = true
			results = append(results, result)
		}
	}

	// Add network results
	for _, result := range networkResults {
		if !seenCTIDs[result.CTID] {
			seenCTIDs[result.CTID] = true
			results = append(results, result)
			if len(results) >= maxResults {
				break
			}
		}
	}

	return results, nil
}

// searchLocal searches in local storage
func (s *Service) searchLocal(tokens []string) []*SearchResult {
	// Search in local storage
	tracks, err := s.store.FindTracksByToken(strings.Join(tokens, " "))
	if err != nil {
		return []*SearchResult{}
	}

	results := make([]*SearchResult, 0, len(tracks))
	for _, track := range tracks {
		if track.CTID == "" {
			continue // Skip tracks without CTID
		}

		results = append(results, &SearchResult{
			CTID:       track.CTID,
			Title:      track.Title,
			Artist:     track.Artist,
			Recognized: track.Recognized,
			Providers:  []string{}, // Local track, no providers needed
		})
	}

	return results
}

// searchNetwork searches in the P2P network according to TZ:
// 1. For each token: FindProviders(/token/<hash>)
// 2. Get CTIDs from peers (via local index query protocol)
// 3. FindProviders(/ctid/<CTID>)
// 4. Return results
func (s *Service) searchNetwork(ctx context.Context, tokens []string, maxResults int) ([]*SearchResult, error) {
	// Step 1: For each token, find providers that have this token
	ctidSet := make(map[string]bool)

	// Collect CTIDs from local index first
	s.mu.RLock()
	for _, token := range tokens {
		if ctids, ok := s.localIndex[token]; ok {
			for _, ctid := range ctids {
				ctidSet[ctid] = true
			}
		}
	}
	s.mu.RUnlock()

	for _, token := range tokens {
		// Hash token
		tokenHash := dhtpkg.HashToken(token)

		// FindProviders(/token/<hash>)
		providers, err := s.dht.FindProvidersForToken(ctx, tokenHash, 10)
		if err != nil {
			// Non-fatal, continue with next token
			continue
		}

		// Step 2: Query each provider for CTIDs matching this token
		// Use the index query protocol to get CTIDs from peer's local index
		for _, provider := range providers {
			// Query peer's local index for this token
			peerCTIDs, err := QueryPeerIndex(ctx, s.host, provider.ID, token)
			if err != nil {
				// Non-fatal, continue with next provider
				continue
			}

			// Add CTIDs to set
			for _, ctid := range peerCTIDs {
				ctidSet[ctid] = true
			}
		}
	}

	// Step 3: For each CTID, find providers via FindProviders(/ctid/<CTID>)
	results := make([]*SearchResult, 0)
	for ctid := range ctidSet {
		if len(results) >= maxResults {
			break
		}

		// FindProviders(/ctid/<CTID>)
		providers, err := s.dht.FindProviders(ctx, ctid, 5)
		if err != nil {
			continue
		}

		// Find track metadata locally if available
		track, err := s.store.FindTrackByCTID(ctid)
		var title, artist string
		var recognized bool
		if err == nil && track != nil {
			title = track.Title
			artist = track.Artist
			recognized = track.Recognized
		} else {
			// Track not in local storage, use placeholder
			title = "Unknown"
			artist = "Unknown"
			recognized = false
		}

		providerStrs := make([]string, 0, len(providers))
		for _, p := range providers {
			providerStrs = append(providerStrs, p.ID.String())
		}

		results = append(results, &SearchResult{
			CTID:       ctid,
			Title:      title,
			Artist:     artist,
			Recognized: recognized,
			Providers:  providerStrs,
		})
	}

	return results, nil
}

// UpdateLocalIndex updates the local token index
func (s *Service) UpdateLocalIndex(track *models.Track) {
	if track.CTID == "" || !track.Recognized {
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	// Tokenize title and artist
	titleTokens := s.tokenize(track.Title)
	artistTokens := s.tokenize(track.Artist)

	allTokens := make(map[string]bool)
	for _, token := range titleTokens {
		allTokens[token] = true
	}
	for _, token := range artistTokens {
		allTokens[token] = true
	}

	// Add to index
	for token := range allTokens {
		if s.localIndex[token] == nil {
			s.localIndex[token] = []string{}
		}

		// Check if CTID already in list
		found := false
		for _, ctid := range s.localIndex[token] {
			if ctid == track.CTID {
				found = true
				break
			}
		}

		if !found {
			s.localIndex[token] = append(s.localIndex[token], track.CTID)
		}
	}
}

// tokenize tokenizes a string into search tokens
func (s *Service) tokenize(text string) []string {
	// Simple tokenization: split by whitespace and punctuation
	text = strings.ToLower(text)

	// Remove punctuation
	text = strings.ReplaceAll(text, ",", " ")
	text = strings.ReplaceAll(text, ".", " ")
	text = strings.ReplaceAll(text, "!", " ")
	text = strings.ReplaceAll(text, "?", " ")
	text = strings.ReplaceAll(text, "-", " ")
	text = strings.ReplaceAll(text, "_", " ")

	// Split by whitespace
	parts := strings.Fields(text)

	// Filter out empty and very short tokens
	tokens := make([]string, 0, len(parts))
	for _, part := range parts {
		if len(part) >= 2 {
			tokens = append(tokens, part)
		}
	}

	return tokens
}

// Tokenize tokenizes a string (exported for use by daemon)
func (s *Service) Tokenize(text string) []string {
	return s.tokenize(text)
}

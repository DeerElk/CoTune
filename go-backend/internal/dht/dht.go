package dht

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"sync"
	"time"

	dht "github.com/libp2p/go-libp2p-kad-dht"
	"github.com/libp2p/go-libp2p-kad-dht/dual"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/peerstore"
	"github.com/libp2p/go-libp2p/core/routing"
	"github.com/multiformats/go-multiaddr"
)

const (
	// ProviderRecordTTL is the TTL for provider records in DHT
	ProviderRecordTTL = 24 * time.Hour
)

// Service wraps the DHT functionality
type Service struct {
	dht            *dual.DHT
	h              host.Host
	mu             sync.RWMutex
	providedKeys   map[string]struct{}
	bootstrapAddrs []string
	retryCancel    context.CancelFunc
}

type Stats struct {
	WANActive        bool           `json:"wan_active"`
	WANRoutingSize   int            `json:"wan_routing_size"`
	LANRoutingSize   int            `json:"lan_routing_size"`
	BucketOccupancy  map[string]int `json:"bucket_occupancy"`
	ProviderKeyCount int            `json:"provider_key_count"`
}

// New creates a new DHT service
func New(ctx context.Context, h host.Host, bootstrapAddrs []string) (*Service, error) {
	// Create dual DHT (supports both IPFS and IPNS)
	dhtService, err := dual.New(
		ctx,
		h,
		dual.DHTOption(
			dht.Mode(dht.ModeServer),
			dht.ProtocolPrefix("/cotune"),
			dht.BucketSize(20),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create DHT: %w", err)
	}

	svc := &Service{
		dht:            dhtService,
		h:              h,
		providedKeys:   make(map[string]struct{}),
		bootstrapAddrs: bootstrapAddrs,
	}

	// Bootstrap if address provided
	if len(bootstrapAddrs) > 0 {
		var connected bool
		for _, addr := range bootstrapAddrs {
			if addr == "" {
				continue
			}
			if err := svc.bootstrap(ctx, addr); err != nil {
				log.Printf("Bootstrap failed for %s: %v", addr, err)
				continue
			}
			connected = true
		}
		if !connected {
			log.Println("No bootstrap peers reachable, continuing without bootstrap")
		}
	} else {
		// Use default bootstrap
		log.Println("No bootstrap addresses provided, using default DHT bootstrap...")
		if err := svc.dht.Bootstrap(ctx); err != nil {
			log.Printf("Default bootstrap failed: %v", err)
		}
	}

	if len(bootstrapAddrs) > 0 {
		retryCtx, cancel := context.WithCancel(context.Background())
		svc.retryCancel = cancel
		go svc.bootstrapRetryLoop(retryCtx)
	}

	return svc, nil
}

func (s *Service) bootstrapRetryLoop(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if s.dht.WANActive() && len(s.h.Network().Peers()) > 0 {
				continue
			}
			var connected bool
			for _, addr := range s.bootstrapAddrs {
				if addr == "" {
					continue
				}
				retryCtx, cancel := context.WithTimeout(ctx, 12*time.Second)
				err := s.bootstrap(retryCtx, addr)
				cancel()
				if err != nil {
					continue
				}
				connected = true
			}
			if connected {
				log.Printf("Bootstrap retry succeeded")
			}
		}
	}
}

func (s *Service) bootstrap(ctx context.Context, addrStr string) error {
	addr, err := multiaddr.NewMultiaddr(addrStr)
	if err != nil {
		return fmt.Errorf("invalid bootstrap address: %w", err)
	}

	info, err := peer.AddrInfoFromP2pAddr(addr)
	if err != nil {
		return fmt.Errorf("failed to parse bootstrap peer: %w", err)
	}

	s.h.Peerstore().AddAddrs(info.ID, info.Addrs, peerstore.PermanentAddrTTL)

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	if err := s.h.Connect(ctx, *info); err != nil {
		return fmt.Errorf("failed to connect to bootstrap: %w", err)
	}

	return s.dht.Bootstrap(ctx)
}

func (s *Service) ensureBootstrapConnectivity(ctx context.Context) error {
	if len(s.bootstrapAddrs) == 0 {
		return nil
	}
	if s.dht.WANActive() && len(s.h.Network().Peers()) > 0 {
		return nil
	}

	var lastErr error
	for _, addr := range s.bootstrapAddrs {
		if addr == "" {
			continue
		}
		tryCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		err := s.bootstrap(tryCtx, addr)
		cancel()
		if err == nil {
			return nil
		}
		lastErr = err
	}

	if lastErr != nil {
		return fmt.Errorf("failed to restore bootstrap connectivity: %w", lastErr)
	}
	return fmt.Errorf("no bootstrap addresses configured")
}

// Provide announces that this peer can provide a CTID
func (s *Service) Provide(ctx context.Context, ctid string) error {
	if err := s.ensureBootstrapConnectivity(ctx); err != nil {
		return err
	}

	// Convert CTID to CID
	cid, err := ctidToCID(ctid)
	if err != nil {
		return fmt.Errorf("invalid CTID: %w", err)
	}

	// Provide in DHT
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	if err := s.dht.Provide(ctx, cid, true); err != nil {
		return fmt.Errorf("failed to provide: %w", err)
	}
	s.trackProvided("ctid:" + ctid)

	return nil
}

// FindProviders finds peers that can provide a CTID
func (s *Service) FindProviders(ctx context.Context, ctid string, max int) ([]peer.AddrInfo, error) {
	if err := s.ensureBootstrapConnectivity(ctx); err != nil {
		log.Printf("FindProviders: bootstrap reconnect failed: %v", err)
	}

	// Convert CTID to CID
	cid, err := ctidToCID(ctid)
	if err != nil {
		return nil, fmt.Errorf("invalid CTID: %w", err)
	}

	// Find providers
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	providers := s.dht.FindProvidersAsync(ctx, cid, max)

	result := make([]peer.AddrInfo, 0, max)
	for p := range providers {
		result = append(result, p)
		if len(result) >= max {
			break
		}
	}

	return result, nil
}

// ProvideToken announces that this peer can provide CTIDs for a token
func (s *Service) ProvideToken(ctx context.Context, tokenHash string) error {
	if err := s.ensureBootstrapConnectivity(ctx); err != nil {
		return err
	}

	cid, err := tokenHashToCID(tokenHash)
	if err != nil {
		return fmt.Errorf("invalid token hash: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	if err := s.dht.Provide(ctx, cid, true); err != nil {
		return fmt.Errorf("failed to provide token: %w", err)
	}
	s.trackProvided("token:" + tokenHash)

	return nil
}

func (s *Service) trackProvided(key string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.providedKeys[key] = struct{}{}
}

func (s *Service) Stats() Stats {
	stats := Stats{
		WANActive:       s.dht.WANActive(),
		BucketOccupancy: make(map[string]int),
	}

	if s.dht.WAN != nil && s.dht.WAN.RoutingTable() != nil {
		rt := s.dht.WAN.RoutingTable()
		stats.WANRoutingSize = rt.Size()
		for cpl := uint(0); cpl < 24; cpl++ {
			n := rt.NPeersForCpl(cpl)
			if n > 0 {
				stats.BucketOccupancy["cpl_"+strconv.FormatUint(uint64(cpl), 10)] = n
			}
		}
	}
	if s.dht.LAN != nil && s.dht.LAN.RoutingTable() != nil {
		stats.LANRoutingSize = s.dht.LAN.RoutingTable().Size()
	}

	s.mu.RLock()
	stats.ProviderKeyCount = len(s.providedKeys)
	s.mu.RUnlock()

	return stats
}

// FindProvidersForToken finds providers for a token (used in search)
func (s *Service) FindProvidersForToken(ctx context.Context, tokenHash string, max int) ([]peer.AddrInfo, error) {
	if err := s.ensureBootstrapConnectivity(ctx); err != nil {
		log.Printf("FindProvidersForToken: bootstrap reconnect failed: %v", err)
	}

	cid, err := tokenHashToCID(tokenHash)
	if err != nil {
		return nil, fmt.Errorf("invalid token hash: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	providers := s.dht.FindProvidersAsync(ctx, cid, max)

	result := make([]peer.AddrInfo, 0, max)
	for p := range providers {
		result = append(result, p)
		if len(result) >= max {
			break
		}
	}

	return result, nil
}

// FindPeer resolves a peer's reachable addresses through DHT routing.
func (s *Service) FindPeer(ctx context.Context, id peer.ID) (peer.AddrInfo, error) {
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	return s.dht.FindPeer(ctx, id)
}

// Close closes the DHT service
func (s *Service) Close() error {
	if s.retryCancel != nil {
		s.retryCancel()
	}
	return s.dht.Close()
}

// Routing returns the routing interface
func (s *Service) Routing() routing.Routing {
	return s.dht
}

// Host returns the libp2p host
func (s *Service) Host() host.Host {
	return s.h
}

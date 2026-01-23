package dht

import (
	"context"
	"fmt"
	"log"
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
	dht *dual.DHT
	h   host.Host
}

// New creates a new DHT service
func New(ctx context.Context, h host.Host, bootstrapAddr string) (*Service, error) {
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
		dht: dhtService,
		h:   h,
	}

	// Bootstrap if address provided
	if bootstrapAddr != "" {
		if err := svc.bootstrap(ctx, bootstrapAddr); err != nil {
			return nil, fmt.Errorf("bootstrap failed: %w", err)
		}
	} else {
		// Use default bootstrap
		log.Println("No bootstrap addresses provided, using default DHT bootstrap...")
		if err := svc.dht.Bootstrap(ctx); err != nil {
			return nil, fmt.Errorf("default bootstrap failed: %w", err)
		}
	}

	return svc, nil
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

// Provide announces that this peer can provide a CTID
func (s *Service) Provide(ctx context.Context, ctid string) error {
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

	return nil
}

// FindProviders finds peers that can provide a CTID
func (s *Service) FindProviders(ctx context.Context, ctid string, max int) ([]peer.AddrInfo, error) {
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
	cid, err := tokenHashToCID(tokenHash)
	if err != nil {
		return fmt.Errorf("invalid token hash: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	if err := s.dht.Provide(ctx, cid, true); err != nil {
		return fmt.Errorf("failed to provide token: %w", err)
	}

	return nil
}

// FindProvidersForToken finds providers for a token (used in search)
func (s *Service) FindProvidersForToken(ctx context.Context, tokenHash string, max int) ([]peer.AddrInfo, error) {
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

// Close closes the DHT service
func (s *Service) Close() error {
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

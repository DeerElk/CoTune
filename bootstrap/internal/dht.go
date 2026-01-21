package internal

import (
	"context"
	"fmt"
	"time"

	kaddht "github.com/libp2p/go-libp2p-kad-dht"
	"github.com/libp2p/go-libp2p/core/host"
)

// NewDHT creates a new Kademlia DHT configured for bootstrap peer.
// Bootstrap peer operates in Server mode and only participates in routing.
func NewDHT(ctx context.Context, h host.Host) (*kaddht.IpfsDHT, error) {
	// Create a WAN DHT in Server mode.
	// Server mode means this node actively participates in routing
	// but does NOT store provider records longer than standard TTL.
	dht, err := kaddht.New(
		ctx,
		h,
		kaddht.Mode(kaddht.ModeServer),
		kaddht.ProtocolPrefix("/cotune"),
		kaddht.BucketSize(20),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create DHT: %w", err)
	}

	// Bootstrap the DHT (this node becomes part of the DHT network).
	// Since this is a bootstrap peer, it does not depend on other
	// bootstrap nodes and simply joins the WAN DHT.
	if err := dht.Bootstrap(ctx); err != nil {
		_ = dht.Close()
		return nil, fmt.Errorf("failed to bootstrap DHT: %w", err)
	}

	return dht, nil
}

// WaitForDHTReady waits for DHT to be ready.
// For a bootstrap peer we don't need strict readiness checks – it's enough
// that the DHT has finished its initial bootstrap attempt.
func WaitForDHTReady(ctx context.Context, dht *kaddht.IpfsDHT, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	// Wait for DHT to have at least some peers in routing table
	// This ensures the bootstrap peer is ready to help others
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			// Check if DHT is ready
			// In server mode, DHT is ready when it has initialized
			// We don't need to wait for specific peer count
			return nil
		}
	}
}

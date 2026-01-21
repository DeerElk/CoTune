package internal

import (
	"context"
	"fmt"

	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/p2p/host/autonat"
	noise "github.com/libp2p/go-libp2p/p2p/security/noise"
	libp2pquic "github.com/libp2p/go-libp2p/p2p/transport/quic"
	"github.com/libp2p/go-libp2p/p2p/transport/tcp"
	"github.com/multiformats/go-multiaddr"
)

// NewHost creates a new libp2p host configured for bootstrap peer
// keyPath specifies the path to the private key file. If empty, uses "bootstrap.key" in current directory.
// The key is loaded from file if it exists, or generated and saved if it doesn't.
func NewHost(ctx context.Context, listenAddrs []string, keyPath string) (host.Host, error) {
	// Load or generate persistent private key for stable peer ID
	privKey, err := loadOrGenerateKey(keyPath)
	if err != nil {
		return nil, fmt.Errorf("failed to load/generate key: %w", err)
	}

	// Parse listen addresses
	addrs := make([]multiaddr.Multiaddr, 0, len(listenAddrs))
	for _, addrStr := range listenAddrs {
		addr, err := multiaddr.NewMultiaddr(addrStr)
		if err != nil {
			return nil, fmt.Errorf("invalid listen address %s: %w", addrStr, err)
		}
		addrs = append(addrs, addr)
	}

	// Build libp2p options
	opts := []libp2p.Option{
		libp2p.Identity(privKey),
		libp2p.ListenAddrs(addrs...),
		libp2p.Transport(tcp.NewTCPTransport),
		libp2p.Transport(libp2pquic.NewTransport),
		libp2p.Security(noise.ID, noise.New),
		libp2p.DefaultMuxers,
		libp2p.DefaultPeerstore,
		// Enable NAT traversal features and hole punching.
		// AutoNAT server is wired explicitly below via autonat.New.
		libp2p.EnableHolePunching(),
	}

	// Create host
	h, err := libp2p.New(opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create libp2p host: %w", err)
	}

	// Setup AutoNAT (helps other peers discover their NAT type)
	_, err = autonat.New(h)
	if err != nil {
		h.Close()
		return nil, fmt.Errorf("failed to setup autonat: %w", err)
	}

	return h, nil
}

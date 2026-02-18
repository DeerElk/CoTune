package host

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/peerstore"
	"github.com/libp2p/go-libp2p/p2p/host/autonat"
	"github.com/libp2p/go-libp2p/p2p/protocol/holepunch"
	"github.com/libp2p/go-libp2p/p2p/protocol/identify"
	noise "github.com/libp2p/go-libp2p/p2p/security/noise"
	libp2pquic "github.com/libp2p/go-libp2p/p2p/transport/quic"
	"github.com/libp2p/go-libp2p/p2p/transport/tcp"
	"github.com/multiformats/go-multiaddr"
)

// New creates a new libp2p host with all required protocols
func New(ctx context.Context, listenAddr string, dataDir string, enableRelay bool) (host.Host, error) {
	// Generate or load private key
	privKey, err := loadOrGenerateKey(dataDir)
	if err != nil {
		return nil, fmt.Errorf("failed to load/generate key: %w", err)
	}

	// Parse one or many listen addresses (comma-separated).
	parts := strings.Split(listenAddr, ",")
	listenAddrs := make([]multiaddr.Multiaddr, 0, len(parts))
	for _, part := range parts {
		addrStr := strings.TrimSpace(part)
		if addrStr == "" {
			continue
		}
		addr, err := multiaddr.NewMultiaddr(addrStr)
		if err != nil {
			return nil, fmt.Errorf("invalid listen address %q: %w", addrStr, err)
		}
		listenAddrs = append(listenAddrs, addr)
	}
	if len(listenAddrs) == 0 {
		return nil, fmt.Errorf("no valid listen addresses provided")
	}

	// Build libp2p options
	announceAddrs := parseAnnounceAddrs(os.Getenv("COTUNE_ANNOUNCE_ADDRS"))
	opts := []libp2p.Option{
		libp2p.Identity(privKey),
		libp2p.ListenAddrs(listenAddrs...),
		libp2p.Transport(tcp.NewTCPTransport),
		libp2p.Transport(libp2pquic.NewTransport),
		libp2p.Security(noise.ID, noise.New),
		libp2p.DefaultMuxers,
		libp2p.DefaultPeerstore,
		libp2p.NATPortMap(),
		libp2p.EnableNATService(),
		// TODO: libp2p.EnableAutoRelay(),
		libp2p.EnableHolePunching(),
		libp2p.EnableRelayService(),
	}
	if len(announceAddrs) > 0 {
		opts = append(opts, libp2p.AddrsFactory(func(existing []multiaddr.Multiaddr) []multiaddr.Multiaddr {
			out := make([]multiaddr.Multiaddr, 0, len(existing)+len(announceAddrs))
			out = append(out, existing...)
			seen := make(map[string]struct{}, len(existing))
			for _, a := range existing {
				seen[a.String()] = struct{}{}
			}
			for _, a := range announceAddrs {
				if _, ok := seen[a.String()]; ok {
					continue
				}
				out = append(out, a)
			}
			return out
		}))
	}

	// Create host
	h, err := libp2p.New(opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create libp2p host: %w", err)
	}

	// Setup Identify
	idService, err := identify.NewIDService(h)
	if err != nil {
		h.Close()
		return nil, fmt.Errorf("failed to setup identify: %w", err)
	}

	// Setup AutoNAT
	_, err = autonat.New(h)
	if err != nil {
		h.Close()
		return nil, fmt.Errorf("failed to setup autonat: %w", err)
	}

	// Setup Relay (if enabled)
	// Relay is enabled via libp2p.EnableRelayService() option above
	// No additional setup needed
	_ = enableRelay

	// Setup Hole Punching
	// EnableHolePunching() in options sets up basic hole punching
	// For advanced usage, we can create a service explicitly
	_, err = holepunch.NewService(
		h,
		idService,
		func() []multiaddr.Multiaddr {
			return h.Addrs()
		},
	)
	if err != nil {
		// Non-fatal: EnableHolePunching() already enabled basic hole punching
		// Log but continue
		fmt.Printf("Warning: failed to setup advanced hole punching: %v\n", err)
	}

	return h, nil
}

// ConnectToPeer connects to a peer by multiaddr
func ConnectToPeer(ctx context.Context, h host.Host, addrStr string) error {
	addr, err := multiaddr.NewMultiaddr(addrStr)
	if err != nil {
		return fmt.Errorf("invalid address: %w", err)
	}

	info, err := peer.AddrInfoFromP2pAddr(addr)
	if err != nil {
		return fmt.Errorf("failed to parse peer info: %w", err)
	}

	h.Peerstore().AddAddrs(info.ID, info.Addrs, peerstore.PermanentAddrTTL)

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	if err := h.Connect(ctx, *info); err != nil {
		return fmt.Errorf("failed to connect: %w", err)
	}

	return nil
}

// ConnectToPeerInfo connects to a peer using peer info JSON
func ConnectToPeerInfo(ctx context.Context, h host.Host, peerID string, addrs []string) error {
	pid, err := peer.Decode(peerID)
	if err != nil {
		return fmt.Errorf("invalid peer ID: %w", err)
	}

	maddrs := make([]multiaddr.Multiaddr, 0, len(addrs))
	for _, addrStr := range addrs {
		addr, err := multiaddr.NewMultiaddr(addrStr)
		if err != nil {
			continue
		}
		maddrs = append(maddrs, addr)
	}

	if len(maddrs) == 0 {
		return fmt.Errorf("no valid addresses provided")
	}

	h.Peerstore().AddAddrs(pid, maddrs, peerstore.PermanentAddrTTL)

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	if err := h.Connect(ctx, peer.AddrInfo{ID: pid, Addrs: maddrs}); err != nil {
		return fmt.Errorf("failed to connect: %w", err)
	}

	return nil
}

func parseAnnounceAddrs(raw string) []multiaddr.Multiaddr {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil
	}

	parts := strings.Split(raw, ",")
	result := make([]multiaddr.Multiaddr, 0, len(parts))
	for _, part := range parts {
		addr := strings.TrimSpace(part)
		if addr == "" {
			continue
		}
		maddr, err := multiaddr.NewMultiaddr(addr)
		if err != nil {
			continue
		}
		result = append(result, maddr)
	}
	return result
}

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/cotune/bootstrap/internal"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/multiformats/go-multiaddr"
)

var (
	listenAddrs = flag.String("listen", "/ip4/0.0.0.0/tcp/4001,/ip4/0.0.0.0/udp/4001/quic-v1", "Comma-separated listen addresses")
	keyPath     = flag.String("key", "bootstrap.key", "Path to private key file (will be generated if doesn't exist)")
	logLevel    = flag.String("log", "info", "Log level: debug, info, warn, error")
	printPeerID = flag.Bool("print-peer-id", false, "Print peer ID derived from -key and exit")
	expectPeerID = flag.String("expect-peer-id", "", "Fail startup if actual peer ID doesn't match this value")
)

func main() {
	flag.Parse()

	// Setup logging
	setupLogging(*logLevel)

	if *printPeerID {
		priv, err := internal.LoadOrGenerateKey(*keyPath)
		if err != nil {
			log.Fatalf("Failed to load key: %v", err)
		}
		pid, err := peer.IDFromPrivateKey(priv)
		if err != nil {
			log.Fatalf("Failed to derive peer ID: %v", err)
		}
		fmt.Println(pid.String())
		return
	}

	log.Println("=== CoTune Bootstrap Peer ===")
	log.Println("This is a temporary bootstrap node for initial network discovery.")
	log.Println("It does NOT store data, index tracks, or participate in content distribution.")
	log.Println("")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Parse listen addresses
	addrStrings := strings.Split(*listenAddrs, ",")
	for i := range addrStrings {
		addrStrings[i] = strings.TrimSpace(addrStrings[i])
	}

	// Create libp2p host
	log.Println("Creating libp2p host...")
	log.Printf("Using key file: %s", *keyPath)
	h, err := internal.NewHost(ctx, addrStrings, *keyPath)
	if err != nil {
		log.Fatalf("Failed to create host: %v", err)
	}
	defer h.Close()

	log.Printf("Peer ID: %s", h.ID().String())
	if *expectPeerID != "" && h.ID().String() != *expectPeerID {
		log.Fatalf("Peer ID mismatch: expected=%s actual=%s", *expectPeerID, h.ID().String())
	}
	log.Println("(This peer ID is stable across restarts thanks to persistent key)")
	log.Printf("Addresses:")
	for _, addr := range h.Addrs() {
		// Format as full multiaddr with peer ID
		fullAddr, err := multiaddr.NewMultiaddr(fmt.Sprintf("%s/p2p/%s", addr.String(), h.ID().String()))
		if err == nil {
			log.Printf("  %s", fullAddr.String())
		} else {
			log.Printf("  %s", addr.String())
		}
	}
	log.Println("")

	// Setup connection tracking
	h.Network().Notify(&connectionNotifier{})

	// Create DHT service
	log.Println("Initializing DHT (Server mode)...")
	dhtService, err := internal.NewDHT(ctx, h)
	if err != nil {
		log.Fatalf("Failed to initialize DHT: %v", err)
	}
	defer dhtService.Close()

	// Wait for DHT to be ready
	log.Println("Waiting for DHT to be ready...")
	if err := internal.WaitForDHTReady(ctx, dhtService, 10*time.Second); err != nil {
		log.Printf("Warning: DHT ready check timed out: %v", err)
	}

	log.Println("Bootstrap peer is ready!")
	log.Println("")
	log.Println("This node will:")
	log.Println("  - Accept incoming connections from new peers")
	log.Println("  - Help peers discover other nodes via DHT")
	log.Println("  - Participate in DHT routing (Server mode)")
	log.Println("  - NOT store provider records")
	log.Println("  - NOT index or stream content")
	log.Println("")

	// Setup periodic stats logging
	statsTicker := time.NewTicker(60 * time.Second)
	defer statsTicker.Stop()

	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-statsTicker.C:
				logStats(h)
			}
		}
	}()

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("")
	log.Println("Shutting down bootstrap peer...")

	// Graceful shutdown
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	// Close DHT
	if err := dhtService.Close(); err != nil {
		log.Printf("Error closing DHT: %v", err)
	}

	// Close host (will close all connections)
	if err := h.Close(); err != nil {
		log.Printf("Error closing host: %v", err)
	}

	// Wait a bit for connections to close
	select {
	case <-shutdownCtx.Done():
		log.Println("Shutdown timeout reached")
	case <-time.After(2 * time.Second):
	}

	log.Println("Bootstrap peer shutdown complete")
	log.Println("")
	log.Println("Note: Existing peers will continue to work without this bootstrap node.")
	log.Println("The network is designed to be resilient to bootstrap peer failures.")
}

// connectionNotifier tracks connections for statistics
type connectionNotifier struct{}

func (cn *connectionNotifier) Connected(n network.Network, c network.Conn) {
	log.Printf("Peer connected: %s", c.RemotePeer().String())
}

func (cn *connectionNotifier) Disconnected(n network.Network, c network.Conn) {
	log.Printf("Peer disconnected: %s", c.RemotePeer().String())
}

func (cn *connectionNotifier) Listen(n network.Network, a multiaddr.Multiaddr)      {}
func (cn *connectionNotifier) ListenClose(n network.Network, a multiaddr.Multiaddr) {}
func (cn *connectionNotifier) OpenedStream(n network.Network, s network.Stream)     {}
func (cn *connectionNotifier) ClosedStream(n network.Network, s network.Stream)     {}

// logStats logs current statistics
func logStats(h host.Host) {
	conns := h.Network().Conns()
	peers := make(map[peer.ID]bool)
	for _, conn := range conns {
		peers[conn.RemotePeer()] = true
	}

	log.Printf("Stats: %d connections, %d unique peers", len(conns), len(peers))
}

// setupLogging configures logging level
func setupLogging(level string) {
	// Simple logging setup
	// In production, you might want to use structured logging
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	switch strings.ToLower(level) {
	case "debug":
		// Enable debug logging if needed
		log.Println("Log level: DEBUG")
	case "info":
		log.Println("Log level: INFO")
	case "warn":
		log.Println("Log level: WARN")
	case "error":
		log.Println("Log level: ERROR")
	default:
		log.Println("Log level: INFO (default)")
	}
}

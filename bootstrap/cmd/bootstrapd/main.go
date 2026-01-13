package main

import (
	"context"
	"encoding/base64"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	libp2p "github.com/libp2p/go-libp2p"
	dht "github.com/libp2p/go-libp2p-kad-dht"
	crypto "github.com/libp2p/go-libp2p/core/crypto"
	network "github.com/libp2p/go-libp2p/core/network"
	peer "github.com/libp2p/go-libp2p/core/peer"
	protocol "github.com/libp2p/go-libp2p/core/protocol"
	connmgr "github.com/libp2p/go-libp2p/p2p/net/connmgr"
	relayv2 "github.com/libp2p/go-libp2p/p2p/protocol/circuitv2/relay"
	multiaddr "github.com/multiformats/go-multiaddr"
)

const (
	defaultListen = "/ip4/0.0.0.0/tcp/4001"
	privKeyFile   = "bootstrap.key"
	protoID       = "/cotune/1.0.0"
)

func main() {
	listen := flag.String(
		"listen",
		getEnv("LISTEN_ADDR", defaultListen),
		"listen multiaddr (libp2p format)",
	)

	keyfile := flag.String(
		"key",
		getEnv("BOOTSTRAP_KEY_PATH", privKeyFile),
		"private key file (base64)",
	)

	publicIP := flag.String(
		"public-ip",
		os.Getenv("PUBLIC_IP"),
		"public IPv4 to advertise (optional)",
	)

	flag.Parse()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 1) Load or generate key
	var priv crypto.PrivKey
	if _, err := os.Stat(*keyfile); err == nil {
		b, err := os.ReadFile(*keyfile)
		if err != nil {
			log.Fatalf("read keyfile: %v", err)
		}
		decoded, err := base64.StdEncoding.DecodeString(string(b))
		if err != nil {
			log.Fatalf("decode key: %v", err)
		}
		priv, err = crypto.UnmarshalPrivateKey(decoded)
		if err != nil {
			log.Fatalf("unmarshal priv key: %v", err)
		}
		log.Printf("Loaded existing key from %s", *keyfile)
	} else {
		var err error
		priv, _, err = crypto.GenerateKeyPair(crypto.Ed25519, -1)
		if err != nil {
			log.Fatalf("generate key: %v", err)
		}
		// Save
		pb, err := crypto.MarshalPrivateKey(priv)
		if err != nil {
			log.Fatalf("marshal priv: %v", err)
		}
		enc := base64.StdEncoding.EncodeToString(pb)
		if err := os.WriteFile(*keyfile, []byte(enc), 0600); err != nil {
			log.Fatalf("write keyfile: %v", err)
		}
		log.Printf("Generated new key -> %s", *keyfile)
	}

	// 2) peer id
	pid, err := peer.IDFromPrivateKey(priv)
	if err != nil {
		log.Fatalf("peer id from priv: %v", err)
	}

	// 3) Build libp2p options
	cm, err := connmgr.NewConnManager(100, 400, connmgr.WithGracePeriod(5*time.Second))
	if err != nil {
		log.Fatalf("connmgr init: %v", err)
	}

	opts := []libp2p.Option{
		libp2p.ListenAddrStrings(*listen),
		libp2p.Identity(priv),
		libp2p.ConnectionManager(cm),
		libp2p.EnableRelay(),
		libp2p.EnableNATService(),
	}

	// Add public IP announce if provided
	if *publicIP != "" {
		pubMaddrStr := fmt.Sprintf("/ip4/%s/tcp/4001", *publicIP)
		pubMaddr, err := multiaddr.NewMultiaddr(pubMaddrStr)
		if err != nil {
			log.Fatalf("bad public multiaddr %q: %v", pubMaddrStr, err)
		}
		opts = append(opts, libp2p.AddrsFactory(func(addrs []multiaddr.Multiaddr) []multiaddr.Multiaddr {
			out := append(addrs, pubMaddr)
			return out
		}))
		log.Printf("Will advertise public address %s", pubMaddr.String())
	} else {
		log.Println("No PUBLIC_IP given; node will advertise local interfaces only.")
	}

	// 4) create host
	h, err := libp2p.New(opts...)
	if err != nil {
		log.Fatalf("create libp2p host: %v", err)
	}
	defer h.Close()

	// 5) Enable relay v2 with options to allow connections between peers with reservations
	// relayv2.New accepts options like relayv2.WithResources, but by default it should allow
	// connections between peers that both have reservations
	_, err = relayv2.New(h)
	if err != nil {
		log.Fatalf("enable relay v2: %v", err)
	}
	log.Printf("Relay v2 enabled - will allow connections between peers with reservations")

	// Track relay reservations and connections
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				// Log active connections through relay
				conns := h.Network().Conns()
				relayConns := 0
				for _, conn := range conns {
					if conn.Stat().Direction == network.DirInbound {
						// Check if this is a relay connection
						for _, addr := range conn.RemoteMultiaddr().Protocols() {
							if addr.Name == "p2p-circuit" {
								relayConns++
								break
							}
						}
					}
				}
				if relayConns > 0 {
					log.Printf("Active relay connections: %d", relayConns)
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	// 6) Initialize DHT in server mode (bootstrap node)
	kdht, err := dht.New(ctx, h, dht.Mode(dht.ModeServer))
	if err != nil {
		log.Fatalf("create DHT: %v", err)
	}
	defer kdht.Close()

	// Bootstrap DHT (as server, we don't need to connect to others)
	if err := kdht.Bootstrap(ctx); err != nil {
		log.Printf("DHT bootstrap warning: %v", err)
	}

	// 7) print peer info and multiaddrs
	log.Println("========================================")
	log.Println("Cotune Bootstrap Node Running")
	log.Println("========================================")
	log.Printf("PeerID: %s", pid.String())
	log.Println("")
	log.Println("Advertised multiaddrs (what others should use):")
	for _, a := range h.Addrs() {
		addrStr := fmt.Sprintf("%s/p2p/%s", a.String(), pid.String())
		log.Printf("  %s", addrStr)
	}

	// additionally print public IP multiaddr explicitly
	if *publicIP != "" {
		pubAddr := fmt.Sprintf("/ip4/%s/tcp/4001/p2p/%s", *publicIP, pid.String())
		log.Printf("  %s (public)", pubAddr)
	}
	log.Println("")
	log.Println("Features enabled:")
	log.Println("  - Relay (circuit v2)")
	log.Println("  - DHT (server mode)")
	log.Println("  - NAT traversal")
	log.Println("========================================")

	// 8) stream handler for basic connectivity test
	h.SetStreamHandler(protocol.ID(protoID), func(s network.Stream) {
		remotePeer := s.Conn().RemotePeer()
		conn := s.Conn()
		// Check if this is a relay connection
		isRelay := false
		for _, addr := range conn.RemoteMultiaddr().Protocols() {
			if addr.Name == "p2p-circuit" {
				isRelay = true
				break
			}
		}
		if isRelay {
			log.Printf("Incoming RELAY connection from: %s via %s", remotePeer.String(), conn.RemoteMultiaddr().String())
		} else {
			log.Printf("Incoming DIRECT connection from: %s", remotePeer.String())
		}
		_ = s.Close()
	})

	// Track network events for relay connections
	h.Network().Notify(&network.NotifyBundle{
		ConnectedF: func(n network.Network, c network.Conn) {
			// Check if this is a relay connection
			for _, addr := range c.RemoteMultiaddr().Protocols() {
				if addr.Name == "p2p-circuit" {
					log.Printf("RELAY connection established: %s -> %s via %s",
						c.LocalPeer().String(), c.RemotePeer().String(), c.RemoteMultiaddr().String())
					return
				}
			}
			log.Printf("Direct connection established: %s -> %s",
				c.LocalPeer().String(), c.RemotePeer().String())
		},
		DisconnectedF: func(n network.Network, c network.Conn) {
			log.Printf("Connection closed: %s -> %s", c.LocalPeer().String(), c.RemotePeer().String())
		},
	})

	// 9) Connection tracking
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				conns := h.Network().Conns()
				if len(conns) > 0 {
					log.Printf("Active connections: %d", len(conns))
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	// 10) Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	log.Println("Press Ctrl+C to stop...")
	<-sigChan
	log.Println("Shutting down...")
}

func getEnv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}


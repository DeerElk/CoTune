package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	protoapi "github.com/cotune/go-backend/internal/api/proto"
	"github.com/cotune/go-backend/internal/ctr"
	"github.com/cotune/go-backend/internal/daemon"
	"github.com/cotune/go-backend/internal/dht"
	"github.com/cotune/go-backend/internal/host"
	"github.com/cotune/go-backend/internal/search"
	"github.com/cotune/go-backend/internal/storage"
	"github.com/cotune/go-backend/internal/streaming"
)

var (
	protoAddr   = flag.String("proto", "127.0.0.1:7777", "Protobuf IPC address (localhost TCP or Unix socket path)")
	httpAddr    = flag.String("http", "", "HTTP API address (deprecated, use -proto)")
	listenAddr  = flag.String("listen", "/ip4/0.0.0.0/tcp/0", "libp2p listen address")
	dataDir     = flag.String("data", "", "Data directory")
	bootstrap   = flag.String("bootstrap", "", "Bootstrap peer multiaddr (optional)")
	enableRelay = flag.Bool("relay", false, "Enable relay service")
)

func main() {
	flag.Parse()

	log.Printf("Flags parsed: proto=%s, listen=%s, data=%s, relay=%v", *protoAddr, *listenAddr, *dataDir, *enableRelay)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup data directory
	if *dataDir == "" {
		// Default to current directory on Android
		*dataDir = "/data/data/ru.apps78.cotune/files/cotune_data"
	}

	log.Printf("Using data directory: %s", *dataDir)
	if err := os.MkdirAll(*dataDir, 0755); err != nil {
		log.Fatalf("Failed to create data directory: %v", err)
	}
	log.Println("Data directory created/verified")

	// Initialize storage
	log.Println("Initializing storage...")
	store, err := storage.New(*dataDir)
	if err != nil {
		log.Fatalf("Failed to initialize storage: %v", err)
	}
	defer store.Close()
	log.Println("Storage initialized")

	// Initialize libp2p host
	log.Println("Initializing libp2p host...")
	h, err := host.New(ctx, *listenAddr, *dataDir, *enableRelay)
	if err != nil {
		log.Fatalf("Failed to create libp2p host: %v", err)
	}
	defer h.Close()

	log.Printf("Peer ID: %s", h.ID().String())
	log.Printf("Addresses: %v", h.Addrs())

	// Initialize DHT
	dhtService, err := dht.New(ctx, h, *bootstrap)
	if err != nil {
		log.Fatalf("Failed to initialize DHT: %v", err)
	}
	defer dhtService.Close()
	log.Println("DHT initialized")

	// Initialize CTR pipeline
	log.Println("Initializing CTR service...")
	ctrService := ctr.New(store, dhtService)
	log.Println("CTR service initialized")

	// Initialize search service
	log.Println("Initializing search service...")
	searchService := search.New(store, dhtService, h)
	log.Println("Search service initialized")

	// Initialize streaming service
	log.Println("Initializing streaming service...")
	streamingService := streaming.New(h, store)
	log.Println("Streaming service initialized")

	// Initialize daemon
	log.Println("Initializing daemon...")
	dm := daemon.New(h, dhtService, ctrService, searchService, streamingService, store)
	log.Println("Daemon initialized")

	// Start daemon
	log.Println("Starting daemon...")
	if err := dm.Start(ctx); err != nil {
		log.Fatalf("Failed to start daemon: %v", err)
	}
	log.Println("Daemon started")

	// Start Protobuf IPC server
	protoAddr := *protoAddr
	if *httpAddr != "" {
		// Backward compatibility: if http is set, use it as proto address
		protoAddr = *httpAddr
		log.Println("Warning: -http flag is deprecated, use -proto instead")
	}

	log.Printf("Starting Protobuf IPC server on %s...", protoAddr)
	apiServer := protoapi.New(protoAddr, dm)
	if err := apiServer.Start(); err != nil {
		log.Fatalf("Protobuf IPC server error: %v", err)
	}

	log.Printf("CoTune daemon started successfully on %s (protobuf IPC)", protoAddr)

	// Wait for interrupt
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Shutting down...")

	// Graceful shutdown
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := apiServer.Shutdown(shutdownCtx); err != nil {
		log.Printf("Error shutting down Protobuf server: %v", err)
	}

	if err := dm.Stop(shutdownCtx); err != nil {
		log.Printf("Error stopping daemon: %v", err)
	}

	log.Println("Shutdown complete")
}

package main

import (
	"context"
	"flag"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	controlapi "github.com/cotune/go-backend/internal/api/control"
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
	mode        = flag.String("mode", "android", "Run mode: android or server")
	protoAddr   = flag.String("proto", "127.0.0.1:7777", "Protobuf IPC address (localhost TCP or Unix socket path)")
	httpAddr    = flag.String("http", "", "HTTP API address (deprecated, use -proto)")
	controlAddr = flag.String("control", "0.0.0.0:8080", "Control HTTP API address")
	listenAddr  = flag.String("listen", "/ip4/0.0.0.0/tcp/0", "libp2p listen address")
	dataDir     = flag.String("data", "", "Data directory")
	enableRelay = flag.Bool("relay", false, "Enable relay service")
	bootstrap   bootstrapAddrs
)

type bootstrapAddrs []string

func (b *bootstrapAddrs) String() string {
	return strings.Join(*b, ",")
}

func (b *bootstrapAddrs) Set(value string) error {
	for _, part := range strings.Split(value, ",") {
		addr := strings.TrimSpace(part)
		if addr != "" {
			*b = append(*b, addr)
		}
	}
	return nil
}

func main() {
	flag.Var(&bootstrap, "bootstrap", "Bootstrap peer multiaddr (repeatable or comma-separated)")
	flag.Parse()
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	if *mode != "android" && *mode != "server" {
		logger.Error("invalid-mode", "mode", *mode)
		os.Exit(2)
	}

	logger.Info("flags-parsed",
		"mode", *mode,
		"proto", *protoAddr,
		"control", *controlAddr,
		"listen", *listenAddr,
		"data", *dataDir,
		"relay", *enableRelay,
		"bootstrap", bootstrap.String(),
	)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup data directory
	if *dataDir == "" {
		if *mode == "server" {
			*dataDir = "./cotune_data"
		} else {
			// Android default.
			*dataDir = "/data/data/ru.apps78.cotune/files/cotune_data"
		}
	}

	logger.Info("using-data-directory", "path", *dataDir)
	if err := os.MkdirAll(*dataDir, 0755); err != nil {
		logger.Error("failed-create-data-directory", "error", err)
		os.Exit(1)
	}
	logger.Info("data-directory-ready")

	// Initialize storage
	logger.Info("initializing-storage")
	store, err := storage.New(*dataDir)
	if err != nil {
		logger.Error("failed-initialize-storage", "error", err)
		os.Exit(1)
	}
	defer store.Close()
	logger.Info("storage-initialized")

	// Initialize libp2p host
	logger.Info("initializing-libp2p-host")
	h, err := host.New(ctx, *listenAddr, *dataDir, *enableRelay)
	if err != nil {
		logger.Error("failed-create-libp2p-host", "error", err)
		os.Exit(1)
	}
	defer h.Close()
	peerLogger := logger.With("peer_id", h.ID().String())

	peerLogger.Info("host-ready", "addresses", h.Addrs())

	// Initialize DHT
	dhtService, err := dht.New(ctx, h, bootstrap)
	if err != nil {
		peerLogger.Error("failed-initialize-dht", "error", err)
		os.Exit(1)
	}
	defer dhtService.Close()
	peerLogger.Info("dht-initialized")

	// Initialize CTR pipeline
	peerLogger.Info("initializing-ctr-service")
	ctrService := ctr.New(store, dhtService)
	peerLogger.Info("ctr-service-initialized")

	// Initialize search service
	peerLogger.Info("initializing-search-service")
	searchService := search.New(store, dhtService, h)
	peerLogger.Info("search-service-initialized")

	// Initialize streaming service
	peerLogger.Info("initializing-streaming-service")
	streamingService := streaming.New(h, store)
	peerLogger.Info("streaming-service-initialized")

	// Initialize daemon
	peerLogger.Info("initializing-daemon")
	dm := daemon.New(h, dhtService, ctrService, searchService, streamingService, store, peerLogger)
	peerLogger.Info("daemon-initialized")

	// Start daemon
	peerLogger.Info("starting-daemon")
	if err := dm.Start(ctx); err != nil {
		peerLogger.Error("failed-start-daemon", "error", err)
		os.Exit(1)
	}
	peerLogger.Info("daemon-started")

	// Start Protobuf IPC server
	protoAddr := *protoAddr
	if *httpAddr != "" {
		// Backward compatibility: if http is set, use it as proto address
		protoAddr = *httpAddr
		peerLogger.Warn("deprecated-http-flag", "http", *httpAddr)
	}

	apiServer := protoapi.New(protoAddr, dm)
	if err := apiServer.Start(); err != nil {
		peerLogger.Error("protobuf-ipc-server-error", "error", err)
		os.Exit(1)
	}
	peerLogger.Info("protobuf-ipc-started", "addr", protoAddr)

	// In Android mode expose control API only on localhost for in-app diagnostics.
	if *mode == "android" && *controlAddr == "0.0.0.0:8080" {
		*controlAddr = "127.0.0.1:8080"
	}

	var controlServer *controlapi.Server
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	stopChan := make(chan struct{}, 1)
	var shutdownOnce sync.Once
	shutdown := func(reason string) {
		shutdownOnce.Do(func() {
			peerLogger.Info("shutdown-requested", "reason", reason)
			stopChan <- struct{}{}
		})
	}

	controlServer = controlapi.New(*controlAddr, dm, peerLogger, func(context.Context) error {
		shutdown("control-api")
		return nil
	})
	if err := controlServer.Start(); err != nil {
		peerLogger.Error("control-api-start-error", "error", err)
		os.Exit(1)
	}
	peerLogger.Info("control-api-started", "addr", *controlAddr)
	peerLogger.Info("cotune-daemon-ready", "mode", *mode)

	go func() {
		sig := <-sigChan
		shutdown(sig.String())
	}()
	<-stopChan

	// Graceful shutdown
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if controlServer != nil {
		if err := controlServer.Shutdown(shutdownCtx); err != nil {
			peerLogger.Warn("error-shutting-down-control-server", "error", err)
		}
	}

	if err := apiServer.Shutdown(shutdownCtx); err != nil {
		peerLogger.Warn("error-shutting-down-protobuf-server", "error", err)
	}

	if err := dm.Stop(shutdownCtx); err != nil {
		peerLogger.Warn("error-stopping-daemon", "error", err)
	}

	peerLogger.Info("shutdown-complete")
}

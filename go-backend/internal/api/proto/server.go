package proto

import (
	"context"
	"fmt"
	"net"
	"os"
	"strings"

	"google.golang.org/grpc"

	protoapi "github.com/cotune/go-backend/api/proto"
	"github.com/cotune/go-backend/internal/daemon"
	"github.com/libp2p/go-libp2p/core/peer"
)

var _ = protoapi.UnimplementedCotuneServiceServer{}

// Server is the protobuf/gRPC IPC server
type Server struct {
	protoapi.UnimplementedCotuneServiceServer
	addr   string
	daemon *daemon.Daemon
	server *grpc.Server
}

// New creates a new protobuf server
func New(addr string, dm *daemon.Daemon) *Server {
	return &Server{
		addr:   addr,
		daemon: dm,
	}
}

// Start starts the protobuf server
func (s *Server) Start() error {
	// Determine if Unix socket or TCP
	var listener net.Listener
	var err error

	if strings.HasPrefix(s.addr, "/") || strings.HasPrefix(s.addr, "unix://") {
		// Unix socket
		socketPath := strings.TrimPrefix(s.addr, "unix://")
		// Remove existing socket file
		os.Remove(socketPath)
		listener, err = net.Listen("unix", socketPath)
		if err != nil {
			return fmt.Errorf("failed to listen on Unix socket: %w", err)
		}
	} else {
		// TCP (localhost)
		listener, err = net.Listen("tcp", s.addr)
		if err != nil {
			return fmt.Errorf("failed to listen on TCP: %w", err)
		}
	}

	s.server = grpc.NewServer()
	protoapi.RegisterCotuneServiceServer(s.server, s)

	go func() {
		if err := s.server.Serve(listener); err != nil {
			fmt.Printf("Protobuf server error: %v\n", err)
		}
	}()

	return nil
}

// Shutdown gracefully shuts down the server
func (s *Server) Shutdown(ctx context.Context) error {
	if s.server != nil {
		s.server.GracefulStop()
	}
	return nil
}

// Status implements CotuneService.Status
func (s *Server) Status(ctx context.Context, req *protoapi.StatusRequest) (*protoapi.StatusResponse, error) {
	return &protoapi.StatusResponse{
		Running: true,
		Version: "1.0.0",
	}, nil
}

// PeerInfo implements CotuneService.PeerInfo
func (s *Server) PeerInfo(ctx context.Context, req *protoapi.PeerInfoRequest) (*protoapi.PeerInfoResponse, error) {
	info := s.daemon.GetPeerInfo()

	peerID, _ := info["peerId"].(string)
	addrs, _ := info["addrs"].([]string)

	peerInfo := &protoapi.PeerInfo{
		PeerId:    peerID,
		Addresses: addrs,
	}

	return &protoapi.PeerInfoResponse{
		PeerInfo: peerInfo,
	}, nil
}

// KnownPeers implements CotuneService.KnownPeers
func (s *Server) KnownPeers(ctx context.Context, req *protoapi.StatusRequest) (*protoapi.KnownPeersResponse, error) {
	peerIDs := s.daemon.GetKnownPeers()
	result := make([]*protoapi.PeerInfo, 0, len(peerIDs))

	for _, peerIDStr := range peerIDs {
		// Get peer info from daemon
		// Note: GetKnownPeers returns []string, we need to get full info
		result = append(result, &protoapi.PeerInfo{
			PeerId:    peerIDStr,
			Addresses: []string{}, // Addresses not available from GetKnownPeers
		})
	}

	return &protoapi.KnownPeersResponse{
		Peers: result,
	}, nil
}

// Connect implements CotuneService.Connect
func (s *Server) Connect(ctx context.Context, req *protoapi.ConnectRequest) (*protoapi.ConnectResponse, error) {
	var err error

	// Handle oneof target field using GetTarget() method
	target := req.GetTarget()
	if target == nil {
		return &protoapi.ConnectResponse{
			Success: false,
			Error:   "no target specified",
		}, nil
	}

	// Type assertion for oneof
	switch t := target.(type) {
	case *protoapi.ConnectRequest_Multiaddr:
		err = s.daemon.ConnectToPeer(ctx, t.Multiaddr)
	case *protoapi.ConnectRequest_PeerInfo:
		pid, err2 := peer.Decode(t.PeerInfo.PeerId)
		if err2 != nil {
			return &protoapi.ConnectResponse{
				Success: false,
				Error:   fmt.Sprintf("invalid peer ID: %v", err2),
			}, nil
		}
		err = s.daemon.ConnectToPeerInfo(ctx, pid.String(), t.PeerInfo.Addresses)
	default:
		return &protoapi.ConnectResponse{
			Success: false,
			Error:   "invalid target type",
		}, nil
	}

	if err != nil {
		return &protoapi.ConnectResponse{
			Success: false,
			Error:   err.Error(),
		}, nil
	}

	return &protoapi.ConnectResponse{
		Success: true,
	}, nil
}

// Search implements CotuneService.Search
func (s *Server) Search(ctx context.Context, req *protoapi.SearchRequest) (*protoapi.SearchResponse, error) {
	maxResults := int(req.GetMaxResults())
	if maxResults == 0 {
		maxResults = 20
	}

	results, err := s.daemon.Search(ctx, req.GetQuery(), maxResults)
	if err != nil {
		return &protoapi.SearchResponse{}, err
	}

	protoResults := make([]*protoapi.SearchResult, 0, len(results))
	for _, r := range results {
		protoResults = append(protoResults, &protoapi.SearchResult{
			Ctid:       r.CTID,
			Title:      r.Title,
			Artist:     r.Artist,
			Recognized: r.Recognized,
			Providers:  r.Providers,
		})
	}

	return &protoapi.SearchResponse{
		Results: protoResults,
	}, nil
}

// SearchProviders implements CotuneService.SearchProviders
func (s *Server) SearchProviders(ctx context.Context, req *protoapi.SearchProvidersRequest) (*protoapi.SearchProvidersResponse, error) {
	max := int(req.GetMax())
	if max == 0 {
		max = 12
	}

	providers, err := s.daemon.FindProviders(ctx, req.GetCtid(), max)
	if err != nil {
		return &protoapi.SearchProvidersResponse{}, err
	}

	providerIDs := make([]string, 0, len(providers))
	for _, p := range providers {
		providerIDs = append(providerIDs, p.ID.String())
	}

	return &protoapi.SearchProvidersResponse{
		ProviderIds: providerIDs,
	}, nil
}

// Fetch implements CotuneService.Fetch
func (s *Server) Fetch(ctx context.Context, req *protoapi.FetchRequest) (*protoapi.FetchResponse, error) {
	var err error

	if req.GetPeerId() != "" {
		// Fetch from specific peer
		pid, err2 := peer.Decode(req.GetPeerId())
		if err2 != nil {
			return &protoapi.FetchResponse{
				Success: false,
				Error:   fmt.Sprintf("invalid peer ID: %v", err2),
			}, nil
		}
		err = s.daemon.FetchTrackFromPeer(ctx, pid, req.GetCtid(), req.GetOutputPath())
	} else {
		// Fetch from network
		err = s.daemon.FetchTrack(ctx, req.GetCtid(), req.GetOutputPath())
	}

	if err != nil {
		return &protoapi.FetchResponse{
			Success: false,
			Error:   err.Error(),
		}, nil
	}

	return &protoapi.FetchResponse{
		Success: true,
		Path:    req.GetOutputPath(),
	}, nil
}

// Share implements CotuneService.Share
func (s *Server) Share(ctx context.Context, req *protoapi.ShareRequest) (*protoapi.ShareResponse, error) {
	err := s.daemon.ShareTrack(ctx, req.GetTrackId())
	if err != nil {
		return &protoapi.ShareResponse{
			Success: false,
			Error:   err.Error(),
		}, nil
	}

	return &protoapi.ShareResponse{
		Success: true,
		Path:    req.GetPath(),
	}, nil
}

// Announce implements CotuneService.Announce
func (s *Server) Announce(ctx context.Context, req *protoapi.AnnounceRequest) (*protoapi.AnnounceResponse, error) {
	// Trigger manual announce (daemon has announceLoop that does this automatically)
	// This is a no-op as announceLoop handles it, but we return success for compatibility
	return &protoapi.AnnounceResponse{
		Success: true,
	}, nil
}

// Relays implements CotuneService.Relays
func (s *Server) Relays(ctx context.Context, req *protoapi.RelaysRequest) (*protoapi.RelaysResponse, error) {
	relays := s.daemon.GetRelayAddresses()
	return &protoapi.RelaysResponse{
		RelayAddresses: relays,
	}, nil
}

// RelayEnable implements CotuneService.RelayEnable
func (s *Server) RelayEnable(ctx context.Context, req *protoapi.RelayEnableRequest) (*protoapi.RelayEnableResponse, error) {
	err := s.daemon.EnableRelay()
	if err != nil {
		return &protoapi.RelayEnableResponse{
			Success: false,
		}, err
	}

	return &protoapi.RelayEnableResponse{
		Success: true,
	}, nil
}

// RelayRequest implements CotuneService.RelayRequest
func (s *Server) RelayRequest(ctx context.Context, req *protoapi.RelayRequestRequest) (*protoapi.RelayRequestResponse, error) {
	_, err := s.daemon.RequestRelayConnection(ctx, req.GetPeerId())
	if err != nil {
		return &protoapi.RelayRequestResponse{
			Success: false,
			Error:   err.Error(),
		}, nil
	}

	// relayAddr contains the relay address, but response doesn't have a field for it
	// Return success
	return &protoapi.RelayRequestResponse{
		Success: true,
	}, nil
}

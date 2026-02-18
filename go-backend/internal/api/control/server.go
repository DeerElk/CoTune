package control

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/cotune/go-backend/internal/daemon"
)

type Server struct {
	addr       string
	dm         *daemon.Daemon
	logger     *slog.Logger
	shutdownFn func(context.Context) error
	server     *http.Server
}

func New(addr string, dm *daemon.Daemon, logger *slog.Logger, shutdownFn func(context.Context) error) *Server {
	if logger == nil {
		logger = slog.Default()
	}
	return &Server{
		addr:       addr,
		dm:         dm,
		logger:     logger,
		shutdownFn: shutdownFn,
	}
}

func (s *Server) Start() error {
	mux := http.NewServeMux()
	mux.HandleFunc("/status", s.handleStatus)
	mux.HandleFunc("/peers", s.handlePeers)
	mux.HandleFunc("/providers", s.handleProviders)
	mux.HandleFunc("/addTrack", s.handleAddTrack)
	mux.HandleFunc("/search", s.handleSearch)
	mux.HandleFunc("/replicate", s.handleReplicate)
	mux.HandleFunc("/disconnect", s.handleDisconnect)
	mux.HandleFunc("/shutdown", s.handleShutdown)
	mux.HandleFunc("/connect", s.handleConnect)
	mux.HandleFunc("/metrics", s.handleMetrics)

	s.server = &http.Server{
		Addr:              s.addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		if err := s.server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			s.logger.Error("control-api-listen-error", "error", err)
		}
	}()
	return nil
}

func (s *Server) Shutdown(ctx context.Context) error {
	if s.server == nil {
		return nil
	}
	return s.server.Shutdown(ctx)
}

func (s *Server) handleStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	writeJSON(w, http.StatusOK, s.dm.Status())
}

func (s *Server) handlePeers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"peers": s.dm.GetKnownPeers(),
	})
}

func (s *Server) handleProviders(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	ctid := r.URL.Query().Get("ctid")
	if ctid == "" {
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"provider_count": s.dm.Status()["provider_count"],
		})
		return
	}

	max := 12
	if raw := r.URL.Query().Get("max"); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 {
			max = v
		}
	}
	providers, err := s.dm.FindProviders(r.Context(), ctid, max)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	ids := make([]string, 0, len(providers))
	for _, p := range providers {
		ids = append(ids, p.ID.String())
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ctid":      ctid,
		"providers": ids,
		"count":     len(ids),
	})
}

func (s *Server) handleAddTrack(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req struct {
		Path   string `json:"path"`
		Title  string `json:"title"`
		Artist string `json:"artist"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body")
		return
	}
	if req.Path == "" {
		writeError(w, http.StatusBadRequest, "path is required")
		return
	}

	track, err := s.dm.AddTrack(r.Context(), req.Path, req.Title, req.Artist)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, track)
}

func (s *Server) handleSearch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req struct {
		Query string `json:"query"`
		Max   int    `json:"max"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body")
		return
	}
	if req.Query == "" {
		writeError(w, http.StatusBadRequest, "query is required")
		return
	}
	if req.Max <= 0 {
		req.Max = 20
	}
	results, err := s.dm.Search(r.Context(), req.Query, req.Max)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"results": results})
}

func (s *Server) handleReplicate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req struct {
		TrackID    string `json:"track_id"`
		CTID       string `json:"ctid"`
		OutputPath string `json:"output_path"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body")
		return
	}

	switch {
	case req.TrackID != "":
		if err := s.dm.ShareTrack(r.Context(), req.TrackID); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]interface{}{"replicated_track_id": req.TrackID})
	case req.CTID != "":
		if req.OutputPath == "" {
			req.OutputPath = fmt.Sprintf("/data/replicated_%d.bin", time.Now().UnixNano())
		}
		if err := s.dm.FetchTrack(r.Context(), req.CTID, req.OutputPath); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]interface{}{"ctid": req.CTID, "path": req.OutputPath})
	default:
		writeError(w, http.StatusBadRequest, "track_id or ctid is required")
	}
}

func (s *Server) handleDisconnect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req struct {
		PeerID string `json:"peer_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body")
		return
	}
	if req.PeerID == "" {
		writeError(w, http.StatusBadRequest, "peer_id is required")
		return
	}
	if err := s.dm.DisconnectPeer(req.PeerID); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"disconnected": req.PeerID})
}

func (s *Server) handleConnect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req struct {
		Multiaddr string   `json:"multiaddr"`
		PeerID    string   `json:"peer_id"`
		Addrs     []string `json:"addrs"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid json body")
		return
	}

	if req.Multiaddr != "" {
		if err := s.dm.ConnectToPeer(r.Context(), req.Multiaddr); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]interface{}{"connected": req.Multiaddr})
		return
	}

	if req.PeerID == "" || len(req.Addrs) == 0 {
		writeError(w, http.StatusBadRequest, "multiaddr or (peer_id + addrs) is required")
		return
	}
	if err := s.dm.ConnectToPeerInfo(r.Context(), req.PeerID, req.Addrs); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"connected_peer_id": req.PeerID})
}

func (s *Server) handleShutdown(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]interface{}{"status": "shutting_down"})
	if s.shutdownFn != nil {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()
			if err := s.shutdownFn(ctx); err != nil {
				s.logger.Error("control-shutdown-error", "error", err)
			}
		}()
	}
}

func (s *Server) handleMetrics(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	status := s.dm.Status()

	peerID, _ := status["peer_id"].(string)
	connected := asInt(status["connected_peers"])
	routing := asInt(status["routing_table_size"])
	providers := asInt(status["provider_count"])
	wanActive := 0
	if asBool(status["wan_active"]) {
		wanActive = 1
	}

	var sb strings.Builder
	sb.WriteString("# HELP cotune_connected_peers Number of connected peers.\n")
	sb.WriteString("# TYPE cotune_connected_peers gauge\n")
	sb.WriteString(fmt.Sprintf("cotune_connected_peers{peer_id=\"%s\"} %d\n", peerID, connected))
	sb.WriteString("# HELP cotune_routing_table_size WAN DHT routing table size.\n")
	sb.WriteString("# TYPE cotune_routing_table_size gauge\n")
	sb.WriteString(fmt.Sprintf("cotune_routing_table_size{peer_id=\"%s\"} %d\n", peerID, routing))
	sb.WriteString("# HELP cotune_provider_count Number of locally announced provider keys.\n")
	sb.WriteString("# TYPE cotune_provider_count gauge\n")
	sb.WriteString(fmt.Sprintf("cotune_provider_count{peer_id=\"%s\"} %d\n", peerID, providers))
	sb.WriteString("# HELP cotune_wan_active Whether WAN DHT is active.\n")
	sb.WriteString("# TYPE cotune_wan_active gauge\n")
	sb.WriteString(fmt.Sprintf("cotune_wan_active{peer_id=\"%s\"} %d\n", peerID, wanActive))

	w.Header().Set("Content-Type", "text/plain; version=0.0.4")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(sb.String()))
}

func writeJSON(w http.ResponseWriter, status int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]interface{}{
		"error":   message,
		"status":  status,
		"success": false,
	})
}

func asInt(v interface{}) int {
	switch n := v.(type) {
	case int:
		return n
	case int32:
		return int(n)
	case int64:
		return int(n)
	case float32:
		return int(n)
	case float64:
		return int(n)
	default:
		return 0
	}
}

func asBool(v interface{}) bool {
	b, ok := v.(bool)
	return ok && b
}


package core

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	peer "github.com/libp2p/go-libp2p/core/peer"
	multiaddr "github.com/multiformats/go-multiaddr"
)

// Максимальный разрешённый размер загружаемого трека (по /share) — 300 MB
const MaxUploadSize = 300 << 20 // 300 MiB

// startHTTPServer теперь возвращает *http.Server, чтобы Node мог его сохранить и корректно Shutdown.
func startHTTPServer(n *CotuneNode, httpAddr string) (*http.Server, error) {
	mux := http.NewServeMux()

	relaySnapshot := func() []string {
		return n.RelaySnapshot()
	}

	// /status
	mux.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		st, _ := n.Status()
		// Добавляем информацию о подключенных пирах
		if n.Host != nil {
			peers := n.Host.Network().Peers()
			log.Printf("/status: node has %d connected peers", len(peers))
			if len(peers) > 0 {
				for _, p := range peers {
					log.Printf("/status: connected to peer %s", p.String())
				}
			}
		}
		writeJSON(w, st)
	})

	// /peerinfo?format=json
	mux.HandleFunc("/peerinfo", func(w http.ResponseWriter, r *http.Request) {
		st, _ := n.Status()
		out := map[string]any{
			"peerId": st.PeerID,
			"addrs":  st.Addrs,
			"relays": relaySnapshot(),
			"ts":     nowMillis(),
		}
		writeJSON(w, out)
	})

	// /known_peers
	mux.HandleFunc("/known_peers", func(w http.ResponseWriter, r *http.Request) {
		kp, err := n.storage.GetKnownPeers()
		if err != nil {
			http.Error(w, "storage error: "+err.Error(), 500)
			return
		}
		writeJSON(w, kp)
	})

	// /relays - возвращает актуальные адреса релэев / публичные адреса известных пиров (удобно для QR/profile)
	mux.HandleFunc("/relays", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, relaySnapshot())
	})

	// /connect - единый endpoint для multiaddr строки или JSON {"peerId":"...","addrs":["..."]}
	mux.HandleFunc("/connect", func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "read body failed: "+err.Error(), 400)
			return
		}
		input := strings.TrimSpace(string(body))
		if input == "" {
			http.Error(w, "empty body", 400)
			return
		}

		var pid peer.ID
		var addrs []multiaddr.Multiaddr

		// If JSON -> parse as {peerId|id, addrs, relays}
		if strings.HasPrefix(input, "{") {
			var req struct {
				PeerID string   `json:"peerId"`
				ID     string   `json:"id"`
				Addrs  []string `json:"addrs"`
				Relays []string `json:"relays"`
			}
			if err := json.Unmarshal(body, &req); err != nil {
				http.Error(w, "bad json: "+err.Error(), 400)
				return
			}
			pstr := req.PeerID
			if pstr == "" {
				pstr = req.ID
			}
			if pstr == "" && len(req.Addrs) == 0 && len(req.Relays) == 0 {
				http.Error(w, "missing peer id and addrs/relays", 400)
				return
			}
			// parse addrs if present
			for _, a := range req.Addrs {
				if strings.TrimSpace(a) == "" {
					continue
				}
				ma, err := multiaddr.NewMultiaddr(a)
				if err != nil {
					http.Error(w, "bad multiaddr in addrs: "+err.Error(), 400)
					return
				}
				addrs = append(addrs, ma)
			}
			// parse relays if present - это адреса других relay-серверов, их тоже нужно сохранить
			for _, r := range req.Relays {
				if strings.TrimSpace(r) == "" {
					continue
				}
				ma, err := multiaddr.NewMultiaddr(r)
				if err != nil {
					// не критично, просто пропускаем
					continue
				}
				// если relay-адрес содержит peer ID, сохраняем его отдельно
				if pi, err := peer.AddrInfoFromP2pAddr(ma); err == nil && pi != nil {
					_ = NewMaybeSavePeerInfo(n.storage, pi)
				} else {
					// если нет peer ID, добавляем к основным адресам для попытки подключения
					addrs = append(addrs, ma)
				}
			}
			// if peerId provided, validate decode
			if pstr != "" {
				pidTmp, err := peer.Decode(pstr)
				if err != nil {
					http.Error(w, "bad peerId: "+err.Error(), 400)
					return
				}
				pid = pidTmp
			}
		} else {
			// treat input as one or multiple multiaddrs (comma/newline/space separated)
			parts := []string{}
			// allow comma-separated
			if strings.ContainsAny(input, ",\n\r") {
				// replace commas with newlines then split by whitespace/newline
				normalized := strings.ReplaceAll(input, ",", "\n")
				for _, ln := range strings.Split(normalized, "\n") {
					if s := strings.TrimSpace(ln); s != "" {
						parts = append(parts, s)
					}
				}
			} else {
				parts = strings.Fields(input)
			}
			for _, p := range parts {
				ma, err := multiaddr.NewMultiaddr(p)
				if err != nil {
					// if one of the parts is a plain peer id, try decode
					if pidCandidate, derr := peer.Decode(p); derr == nil {
						pid = pidCandidate
						continue
					}
					http.Error(w, "bad multiaddr: "+err.Error(), 400)
					return
				}
				// try to extract peer info if multiaddr contains /p2p/<id>
				if pi, err := peer.AddrInfoFromP2pAddr(ma); err == nil && pi != nil {
					pid = pi.ID
					addrs = append(addrs, pi.Addrs...)
				} else {
					addrs = append(addrs, ma)
				}
			}
		}

		// At this point we must have either pid + addrs, or at least a multiaddr that contains /p2p/<id>.
		if pid == "" && len(addrs) == 0 {
			http.Error(w, "no valid peer information found", 400)
			return
		}

		// If we still don't have peer ID but some addrs include /p2p/<id>, try to extract from first such addr
		if pid == "" {
			for _, ma := range addrs {
				if pi, err := peer.AddrInfoFromP2pAddr(ma); err == nil && pi != nil && pi.ID != "" {
					pid = pi.ID
					// replace addrs with pi.Addrs (cleaned)
					addrs = pi.Addrs
					break
				}
			}
		}

		// If still no peer ID -> error (need peerId for persistent storage)
		if pid == "" {
			http.Error(w, "missing peer id", 400)
			return
		}

		// build AddrInfo for connect: strip any /p2p/<id> from addrs (AddrInfo.Addrs should be addresses without p2p component or ok with it)
		addrInfos := append([]multiaddr.Multiaddr{}, addrs...)
		pi := peer.AddrInfo{ID: pid, Addrs: addrInfos}

		// add to peerstore + try connect
		if len(pi.Addrs) > 0 {
			// normalize (remove any /p2p/... suffixes)
			cleaned := normalizeAddrs(pi.Addrs)
			n.Host.Peerstore().AddAddrs(pi.ID, cleaned, time.Hour)
		}
		ctx, cancel := contextWithTimeout(8 * time.Second)
		defer cancel()
		if err := n.Host.Connect(ctx, pi); err != nil {
			http.Error(w, "connect failed: "+err.Error(), 500)
			return
		}

		// Save addresses in storage as strings; if an addr doesn't contain "/p2p/" append it for readability
		strAddrs := []string{}
		seen := map[string]struct{}{}
		for _, a := range pi.Addrs {
			s := a.String()
			if !strings.Contains(s, "/p2p/") {
				s = s + "/p2p/" + pi.ID.String()
			}
			if _, ok := seen[s]; !ok {
				seen[s] = struct{}{}
				strAddrs = append(strAddrs, s)
			}
		}
		_ = n.storage.SavePeerInfo(pi.ID.String(), strAddrs)

		w.WriteHeader(204)
	})

	// /relay_request - try find relay (simple)
	mux.HandleFunc("/relay_request", func(w http.ResponseWriter, r *http.Request) {
		var req map[string]string
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "bad json: "+err.Error(), 400)
			return
		}
		target := req["target"]
		if target == "" {
			http.Error(w, "missing target", 400)
			return
		}
		// search known peers for p2p-circuit addresses
		known, _ := n.storage.GetKnownPeers()
		for _, addrs := range known {
			for _, a := range addrs {
				if strings.Contains(a, "/p2p-circuit/") || strings.Contains(a, "/p2p-circuit") {
					writeJSON(w, map[string]string{"relay": a})
					return
				}
			}
		}
		for _, p := range n.Host.Network().Peers() {
			for _, a := range n.Host.Peerstore().Addrs(p) {
				if strings.Contains(a.String(), "p2p-circuit") {
					writeJSON(w, map[string]string{"relay": a.String() + "/p2p/" + p.String()})
					return
				}
			}
		}
		w.WriteHeader(404)
		writeJSON(w, map[string]string{"relay": ""})
	})

	// /announce - re-announce all local tracks
	mux.HandleFunc("/announce", func(w http.ResponseWriter, r *http.Request) {
		metas, err := n.storage.AllTrackMetas()
		if err != nil {
			http.Error(w, "storage error: "+err.Error(), 500)
			return
		}
		for _, m := range metas {
			if err := n.AnnounceTrack(m); err != nil {
				log.Printf("announce: failed for id=%s: %v", m.ID, err)
			}
		}
		w.WriteHeader(204)
	})

	// /share - POST JSON {id, path, title?, artist?, checksum?, recognized?}
	// копирует файл внутрь storagePath и объявляет трек
	mux.HandleFunc("/share", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("/share: received request")
		var req struct {
			ID         string `json:"id"`
			Path       string `json:"path"`
			Title      string `json:"title"`
			Artist     string `json:"artist"`
			Checksum   string `json:"checksum"`
			Recognized *bool  `json:"recognized,omitempty"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			log.Printf("/share: bad json: %v", err)
			http.Error(w, "bad json: "+err.Error(), 400)
			return
		}
		log.Printf("/share: id=%s, path=%s, title=%s, artist=%s", req.ID, req.Path, req.Title, req.Artist)
		if req.ID == "" || req.Path == "" {
			log.Printf("/share: missing id or path")
			http.Error(w, "missing id or path", 400)
			return
		}
		// ensure source exists
		stSrc, err := os.Stat(req.Path)
		if err != nil {
			http.Error(w, "source file not accessible: "+err.Error(), 400)
			return
		}
		// size check
		if stSrc.Size() > MaxUploadSize {
			http.Error(w, "source file too large", 400)
			return
		}
		// copy into storagePath
		targetDir := n.storage.StoragePath()
		if err := os.MkdirAll(targetDir, 0o755); err != nil {
			http.Error(w, "mkdir failed: "+err.Error(), 500)
			return
		}
		// safe name
		safeID := safeFileName(req.ID)
		if safeID == "" {
			http.Error(w, "invalid id", 400)
			return
		}
		safeName := safeID + "_" + time.Now().Format("20060102_150405")
		dest := filepath.Join(targetDir, safeName+".dat")
		srcF, err := os.Open(req.Path)
		if err != nil {
			http.Error(w, "open source failed: "+err.Error(), 500)
			return
		}
		defer srcF.Close()
		dstF, err := os.Create(dest)
		if err != nil {
			http.Error(w, "create dest failed: "+err.Error(), 500)
			return
		}
		closed := false
		defer func() {
			if !closed {
				dstF.Close()
			}
		}()
		// copy with limit
		if _, err := io.Copy(dstF, io.LimitReader(srcF, MaxUploadSize+1)); err != nil {
			_ = dstF.Close()
			_ = os.Remove(dest)
			http.Error(w, "copy failed: "+err.Error(), 500)
			return
		}
		closed = true
		_ = dstF.Close()
		fi, _ := os.Stat(dest)
		// recognized flag: если авто-распознавания нет (title/artist пустые) и флаг не передан — считаем нераспознанным
		recognized := false
		if req.Recognized != nil {
			recognized = *req.Recognized
		} else if req.Title != "" || req.Artist != "" {
			recognized = true
		}
		owner := ""
		if n.Host != nil {
			owner = n.Host.ID().String()
		}
		meta := &TrackMeta{
			ID:         req.ID,
			Title:      req.Title,
			Artist:     req.Artist,
			Owner:      owner,
			Path:       dest,
			Recognized: recognized,
			Checksum:   req.Checksum,
			Size:       fi.Size(),
			Ts:         nowMillis(),
		}
		log.Printf("/share: created TrackMeta, calling AnnounceTrack...")
		if err := n.AnnounceTrack(meta); err != nil {
			log.Printf("/share: announce failed for %s: %v", meta.ID, err)
		} else {
			log.Printf("/share: successfully announced track %s", meta.ID)
		}
		writeJSON(w, map[string]any{"path": dest})
	})

	// /tag - обновить метаданные уже добавленного трека (ручная подпись title/artist, recognized)
	mux.HandleFunc("/tag", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			ID         string `json:"id"`
			Title      string `json:"title"`
			Artist     string `json:"artist"`
			Checksum   string `json:"checksum"`
			Recognized *bool  `json:"recognized,omitempty"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "bad json: "+err.Error(), 400)
			return
		}
		if strings.TrimSpace(req.ID) == "" {
			http.Error(w, "missing id", 400)
			return
		}
		// load existing meta to preserve path/owner/providers
		exist, err := n.storage.GetTrackMeta(req.ID)
		if err != nil || exist == nil {
			http.Error(w, "track not found", 404)
			return
		}
		recognized := true
		if req.Recognized != nil {
			recognized = *req.Recognized
		}
		owner := exist.Owner
		if owner == "" && n.Host != nil {
			owner = n.Host.ID().String()
		}
		meta := &TrackMeta{
			ID:            req.ID,
			Title:         firstNonEmpty(req.Title, exist.Title),
			Artist:        firstNonEmpty(req.Artist, exist.Artist),
			Owner:         owner,
			Path:          exist.Path,
			Recognized:    recognized,
			Checksum:      firstNonEmpty(req.Checksum, exist.Checksum),
			Size:          exist.Size,
			Ts:            nowMillis(),
			ProviderAddrs: exist.ProviderAddrs,
		}
		if err := n.AnnounceTrack(meta); err != nil {
			log.Printf("tag: announce failed for %s: %v", meta.ID, err)
		}
		writeJSON(w, meta)
	})

	// /search?q=...
	// Поиск работает по локальному кэшу (метаданные приходят через PubSub)
	// Если локально ничего не найдено, ищем через DHT провайдеров и запрашиваем метаданные
	mux.HandleFunc("/search", func(w http.ResponseWriter, r *http.Request) {
		q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))
		log.Printf("/search: query=%q", q)
		res := []TrackMeta{}
		if q == "" {
			writeJSON(w, res)
			return
		}
		// Общие структуры для дедупликации и объединения результатов
		metas, _ := n.storage.AllTrackMetas()
		log.Printf("/search: found %d total tracks in storage", len(metas))
		seen := map[string]struct{}{}
		var mu sync.Mutex

		addIfMatch := func(m *TrackMeta) {
			if m == nil {
				return
			}
			titleMatch := strings.Contains(strings.ToLower(m.Title), q)
			artistMatch := strings.Contains(strings.ToLower(m.Artist), q)
			if !titleMatch && !artistMatch {
				return
			}
			mu.Lock()
			defer mu.Unlock()
			if _, ok := seen[m.ID]; ok {
				return
			}
			seen[m.ID] = struct{}{}
			res = append(res, *m)
		}

		// 1) Локальный поиск (быстрый)
		for _, m := range metas {
			addIfMatch(m)
		}

		// 2) Параллельно ищем через DHT у провайдеров и тянем метаданные по stream-протоколу
		if n.DHT != nil {
			log.Printf("/search: also searching via DHT in parallel...")
			ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
			defer cancel()

			var wg sync.WaitGroup
			sem := make(chan struct{}, 4) // ограничиваем параллелизм

			// Собираем все уникальные trackID из локального хранилища
			trackIDs := make(map[string]struct{})
			for _, m := range metas {
				trackIDs[m.ID] = struct{}{}
			}

			// Собираем всех уникальных провайдеров для всех треков
			allProviders := make(map[string]peer.AddrInfo) // key: peer.ID.String()
			myID := n.Host.ID()
			for trackID := range trackIDs {
				providers, err := n.FindProviders(trackID, 10)
				if err != nil {
					log.Printf("/search: FindProviders error for track %s: %v", trackID, err)
					continue
				}
				log.Printf("/search: FindProviders returned %d providers for track %s", len(providers), trackID)
				for _, pi := range providers {
					if pi.ID == myID {
						log.Printf("/search: skipping self provider %s", pi.ID.String())
						continue
					}
					log.Printf("/search: found OTHER provider %s for track %s", pi.ID.String(), trackID)
					allProviders[pi.ID.String()] = pi
				}
			}

			log.Printf("/search: found %d unique OTHER providers via DHT (excluding self)", len(allProviders))

			// Для каждого провайдера запрашиваем метаданные всех известных треков
			for _, pi := range allProviders {
				wg.Add(1)
				go func(provider peer.AddrInfo) {
					defer wg.Done()
					sem <- struct{}{}
					defer func() { <-sem }()

					// Запрашиваем метаданные для всех известных trackID у этого провайдера
					for trackID := range trackIDs {
						// уважаем таймаут запроса
						select {
						case <-ctx.Done():
							return
						default:
						}

						// Пропускаем, если это сам узел
						if provider.ID == n.Host.ID() {
							log.Printf("/search: skipping self provider %s", provider.ID.String())
							continue
						}

						log.Printf("/search: requesting meta from provider %s for track %s", provider.ID.String(), trackID)
						meta, err := n.GetTrackMetaFromPeer(provider.ID.String(), trackID)
						if err != nil {
							log.Printf("/search: failed to get meta from %s for track %s: %v", provider.ID.String(), trackID, err)
							// Это нормально - провайдер может не иметь этот конкретный трек
							continue
						}
						if meta != nil {
							log.Printf("/search: got meta from %s: id=%s, title=%s, artist=%s", provider.ID.String(), meta.ID, meta.Title, meta.Artist)
							addIfMatch(meta)
							// кэшируем
							_ = n.storage.MergeAndSaveTrackMeta(meta)
						}
					}
				}(pi)
			}
			wg.Wait()
		}

		log.Printf("/search: returning %d results", len(res))
		writeJSON(w, res)
	})

	// /fetch?peer=&id=
	mux.HandleFunc("/fetch", func(w http.ResponseWriter, r *http.Request) {
		pid := r.URL.Query().Get("peer")
		id := r.URL.Query().Get("id")
		if pid == "" || id == "" {
			http.Error(w, "missing peer or id", 400)
			return
		}
		// fetch from node
		path, err := n.FetchFromPeer(pid, id)
		if err != nil {
			http.Error(w, "fetch failed: "+err.Error(), 500)
			return
		}
		writeJSON(w, map[string]any{"path": path})
	})

	// /search_providers?id=<trackID>&max=10
	mux.HandleFunc("/search_providers", func(w http.ResponseWriter, r *http.Request) {
		id := strings.TrimSpace(r.URL.Query().Get("id"))
		if id == "" {
			http.Error(w, "missing id", 400)
			return
		}
		maxStr := r.URL.Query().Get("max")
		max := 10
		if maxStr != "" {
			if v, err := strconv.Atoi(maxStr); err == nil && v > 0 {
				max = v
			}
		}
		// use pubsub/storage cache first
		out := []string{}
		seen := map[string]struct{}{}
		if meta, err := n.storage.GetTrackMeta(id); err == nil && meta != nil {
			for _, a := range meta.ProviderAddrs {
				if a == "" {
					continue
				}
				if _, ok := seen[a]; ok {
					continue
				}
				seen[a] = struct{}{}
				out = append(out, a)
			}
		}
		// if still need more — query DHT
		if max <= 0 || len(out) < max {
			provs, err := n.FindProviders(id, max)
			if err != nil {
				http.Error(w, "find providers failed: "+err.Error(), 500)
				return
			}
			for _, pi := range provs {
				for _, a := range pi.Addrs {
					s := a.String()
					if !strings.Contains(s, "/p2p/") {
						s = s + "/p2p/" + pi.ID.String()
					}
					if _, ok := seen[s]; ok {
						continue
					}
					seen[s] = struct{}{}
					out = append(out, s)
				}
				// if no addrs, include peer id only
				if len(pi.Addrs) == 0 {
					pidStr := pi.ID.String()
					if _, ok := seen[pidStr]; !ok {
						seen[pidStr] = struct{}{}
						out = append(out, pidStr)
					}
				}
			}
		}
		writeJSON(w, out)
	})

	// /relay/enable - promote this node to relay
	mux.HandleFunc("/relay/enable", func(w http.ResponseWriter, r *http.Request) {
		if n.Host == nil {
			http.Error(w, "node not started", 500)
			return
		}
		if err := n.EnableRelay(); err != nil {
			http.Error(w, "enable relay failed: "+err.Error(), 500)
			return
		}
		w.WriteHeader(204)
	})

	// /like - POST JSON {"peer":"<peerid>","id":"<trackid>"}
	mux.HandleFunc("/like", func(w http.ResponseWriter, r *http.Request) {
		var req struct{ Peer, ID string }
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "bad json: "+err.Error(), 400)
			return
		}
		if req.Peer == "" || req.ID == "" {
			http.Error(w, "missing peer or id", 400)
			return
		}
		path, err := n.FetchFromPeer(req.Peer, req.ID)
		if err != nil {
			http.Error(w, "fetch failed: "+err.Error(), 500)
			return
		}
		meta := &TrackMeta{
			ID:         req.ID,
			Title:      req.ID,
			Artist:     "Unknown",
			Owner:      n.Host.ID().String(),
			Path:       path,
			Recognized: true,
			Ts:         nowMillis(),
		}
		_ = n.storage.MergeAndSaveTrackMeta(meta)
		_ = n.AnnounceTrack(meta)
		writeJSON(w, map[string]any{"path": path})
	})

	// Prepare HTTP server: try bind first so caller immediately knows if port is taken
	netListener, err := net.Listen("tcp", httpAddr)
	if err != nil {
		log.Printf("startHTTPServer: failed to listen on %s: %v", httpAddr, err)
		return nil, err
	}
	log.Printf("startHTTPServer: listening on %s", httpAddr)

	srv := &http.Server{
		Addr:              httpAddr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}
	go func() {
		if err := srv.Serve(netListener); err != nil && err != http.ErrServerClosed {
			log.Printf("http server error: %v", err)
		}
	}()
	return srv, nil
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

func contextWithTimeout(d time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), d)
}

// safeFileName делает ID допустимым в качестве имени файла: оставляет только [A-Za-z0-9._-]
// и ограничивает длину.
func safeFileName(id string) string {
	if id == "" {
		return ""
	}
	maxLen := 64
	out := make([]rune, 0, len(id))
	for _, r := range id {
		if isAllowedIDChar(r) {
			out = append(out, r)
		}
		if len(out) >= maxLen {
			break
		}
	}
	return string(out)
}

func isAllowedIDChar(r rune) bool {
	if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') {
		return true
	}
	if r >= '0' && r <= '9' {
		return true
	}
	if r == '-' || r == '_' || r == '.' {
		return true
	}
	return false
}

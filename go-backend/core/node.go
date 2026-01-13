package core

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	libp2p "github.com/libp2p/go-libp2p"
	dht "github.com/libp2p/go-libp2p-kad-dht"
	pubsub "github.com/libp2p/go-libp2p-pubsub"
	host "github.com/libp2p/go-libp2p/core/host"
	network "github.com/libp2p/go-libp2p/core/network"
	peer "github.com/libp2p/go-libp2p/core/peer"
	connmgr "github.com/libp2p/go-libp2p/p2p/net/connmgr"
	relayv2client "github.com/libp2p/go-libp2p/p2p/protocol/circuitv2/client"
	relayv2 "github.com/libp2p/go-libp2p/p2p/protocol/circuitv2/relay"
	multiaddr "github.com/multiformats/go-multiaddr"
)

type CotuneNode struct {
	ctx    context.Context
	cancel context.CancelFunc

	Host   host.Host
	DHT    *dht.IpfsDHT
	PubSub *pubsub.PubSub

	storage *Storage

	pubsubTopic string

	// single topic + subscription to reuse
	pubTopic   *pubsub.Topic
	pubSubSub  *pubsub.Subscription
	publishMu  sync.Mutex
	httpAddr   string
	httpServer *http.Server

	bootstrapAddrs []multiaddr.Multiaddr

	extraMu    sync.Mutex
	extraAddrs []multiaddr.Multiaddr

	mu      sync.Mutex
	started bool
}

var globalNode *CotuneNode

// defaultBootstrapAddrs — вшитая bootstrap-нода (можно переопределить через ENV COTUNE_BOOTSTRAP)
var defaultBootstrapAddrs = []string{
	// example relay; замените на реальный адрес при сборке
	"/ip4/84.201.172.91/tcp/4001/p2p/12D3KooWPg8PavCBcMzooYYHbnoEN5YttQng3YGABvVwkbM5gvPb",
}

func NewCotuneNode(basePath, httpAddr string) (*CotuneNode, error) {
	// create storage
	st, err := NewStorage(basePath)
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithCancel(context.Background())
	return &CotuneNode{
		ctx:         ctx,
		cancel:      cancel,
		storage:     st,
		pubsubTopic: "cotune:tracks",
		httpAddr:    httpAddr,
	}, nil
}

// Start with listen multiaddr like "/ip4/0.0.0.0/tcp/0" (0 = random port)
func (n *CotuneNode) Start(listen string, relays []string) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.started {
		return errors.New("already started")
	}

	// connection manager
	cm, err := connmgr.NewConnManager(100, 400, connmgr.WithGracePeriod(5*time.Second))
	if err != nil {
		return fmt.Errorf("connmgr init failed: %w", err)
	}

	opts := []libp2p.Option{

		libp2p.ConnectionManager(cm),
		libp2p.EnableRelay(),      // enable relay capabilities
		libp2p.EnableNATService(), // helps with hole punching
		// AutoRelay using peer source from known/boot peers to silence SA1019 and keep functionality.
		libp2p.EnableAutoRelayWithPeerSource(func(ctx context.Context, num int) <-chan peer.AddrInfo {
			ch := make(chan peer.AddrInfo, num)
			go func() {
				defer close(ch)
				// First, add bootstrap relays from the provided list
				bootstrapList := dedupStrings(relays)
				if len(bootstrapList) == 0 {
					bootstrapList = append(bootstrapList, defaultBootstrapAddrs...)
				}
				for _, r := range bootstrapList {
					if len(ch) >= num {
						return
					}
					if strings.TrimSpace(r) == "" {
						continue
					}
					ma, err := multiaddr.NewMultiaddr(r)
					if err != nil {
						continue
					}
					pi, err := peer.AddrInfoFromP2pAddr(ma)
					if err != nil {
						continue
					}
					// Only add if it looks like a relay/public address
					hasPublic := false
					for _, a := range pi.Addrs {
						if looksRelayOrPublic(a.String()) {
							hasPublic = true
							break
						}
					}
					if hasPublic || len(pi.Addrs) > 0 {
						ch <- *pi
					}
				}
				// Then feed known peers that look public/relay
				if n.storage != nil {
					if kp, err := n.storage.GetKnownPeers(); err == nil {
						for pid, addrs := range kp {
							if len(ch) >= num {
								return
							}
							p, err := peer.Decode(pid)
							if err != nil {
								continue
							}
							pi := peer.AddrInfo{ID: p}
							for _, a := range addrs {
								if !looksRelayOrPublic(a) {
									continue
								}
								if ma, err := multiaddr.NewMultiaddr(a); err == nil {
									pi.Addrs = append(pi.Addrs, ma)
								}
							}
							if len(pi.Addrs) > 0 {
								ch <- pi
							}
						}
					}
				}
			}()
			return ch
		}),
		// Always advertise extra addrs (e.g., relay /p2p-circuit) that we might add later
		libp2p.AddrsFactory(func(addrs []multiaddr.Multiaddr) []multiaddr.Multiaddr {
			n.extraMu.Lock()
			defer n.extraMu.Unlock()
			seen := map[string]struct{}{}
			out := []multiaddr.Multiaddr{}
			for _, a := range addrs {
				s := a.String()
				if _, ok := seen[s]; ok {
					continue
				}
				seen[s] = struct{}{}
				out = append(out, a)
			}
			for _, a := range n.extraAddrs {
				s := a.String()
				if _, ok := seen[s]; ok {
					continue
				}
				seen[s] = struct{}{}
				out = append(out, a)
			}
			return out
		}),
	}

	// listen addr
	if listen != "" {
		ma, err := multiaddr.NewMultiaddr(listen)
		if err == nil {
			opts = append(opts, libp2p.ListenAddrs(ma))
		}
	}

	h, err := libp2p.New(opts...)
	if err != nil {
		return err
	}

	// DHT
	kdht, err := dht.New(n.ctx, h, dht.Mode(dht.ModeAuto))
	if err != nil {
		_ = h.Close()
		return err
	}

	// Build bootstrap list: provided relays -> env -> known peers -> default
	bootstrapList := dedupStrings(relays)
	if env := strings.TrimSpace(os.Getenv("COTUNE_BOOTSTRAP")); env != "" {
		for _, s := range strings.Split(env, ",") {
			if strings.TrimSpace(s) != "" {
				bootstrapList = append(bootstrapList, strings.TrimSpace(s))
			}
		}
	}
	if len(bootstrapList) == 0 {
		if kp, _ := n.storage.GetKnownPeers(); len(kp) > 0 {
			for _, addrs := range kp {
				for _, a := range addrs {
					if looksRelayOrPublic(a) {
						bootstrapList = append(bootstrapList, a)
					}
				}
			}
		}
	}
	if len(bootstrapList) == 0 {
		bootstrapList = append(bootstrapList, defaultBootstrapAddrs...)
	}

	var parsedBootstrap []multiaddr.Multiaddr
	for _, r := range bootstrapList {
		if strings.TrimSpace(r) == "" {
			continue
		}
		if ma, err := multiaddr.NewMultiaddr(r); err == nil {
			parsedBootstrap = append(parsedBootstrap, ma)
		}
	}
	n.bootstrapAddrs = parsedBootstrap

	// try to connect to provided relays (bootstrap)
	for _, ma := range parsedBootstrap {
		pi, err := peer.AddrInfoFromP2pAddr(ma)
		if err != nil {
			log.Printf("Start: AddrInfoFromP2pAddr failed for %q: %v", ma.String(), err)
			continue
		}
		if err := h.Connect(n.ctx, *pi); err != nil {
			log.Printf("Start: connect to relay %s failed: %v", pi.ID.String(), err)
		} else {
			log.Printf("Start: successfully connected to bootstrap relay %s", pi.ID.String())
			// Try to reserve a slot on the relay so that p2p-circuit dialing works
			if res, err := relayv2client.Reserve(n.ctx, h, *pi); err != nil {
				log.Printf("Start: relay reservation failed with %s: %v", pi.ID.String(), err)
			} else {
				log.Printf("Start: relay reservation ok with %s, expires at %v", pi.ID.String(), res.Expiration)
				if relayAddr := buildRelayCircuitAddr(ma, h.ID()); relayAddr != nil {
					// Advertise our relay reachable address
					h.Peerstore().AddAddrs(h.ID(), []multiaddr.Multiaddr{relayAddr}, time.Hour)
					n.extraMu.Lock()
					n.extraAddrs = append(n.extraAddrs, relayAddr)
					n.extraMu.Unlock()
					log.Printf("Start: added relay circuit addr to self peerstore: %s", relayAddr.String())
				}
				// Start periodic reservation renewal to keep it active
				go n.renewRelayReservation(ma, res.Expiration)
			}
			// save in storage for potential later use
			_ = NewMaybeSavePeerInfo(n.storage, pi)
		}
	}

	// bootstrap the DHT (background)
	go func() {
		log.Printf("Start: bootstrapping DHT...")
		if err := kdht.Bootstrap(n.ctx); err != nil {
			log.Printf("Start: DHT bootstrap error: %v", err)
		} else {
			log.Printf("Start: DHT bootstrap completed")
		}
	}()

	// PubSub
	log.Printf("Start: initializing PubSub (GossipSub)...")
	ps, err := pubsub.NewGossipSub(n.ctx, h)
	if err != nil {
		log.Printf("Start: failed to create PubSub: %v", err)
		_ = h.Close()
		return err
	}
	log.Printf("Start: PubSub created successfully")

	// join topic ONCE and create subscription
	log.Printf("Start: joining pubsub topic: %s", n.pubsubTopic)
	topic, err := ps.Join(n.pubsubTopic)
	if err != nil {
		log.Printf("Start: failed to join topic: %v", err)
		_ = h.Close()
		return err
	}
	log.Printf("Start: joined topic successfully")
	sub, err := topic.Subscribe()
	if err != nil {
		log.Printf("Start: failed to subscribe: %v", err)
		_ = topic.Close()
		_ = h.Close()
		return err
	}
	log.Printf("Start: subscribed to topic successfully")

	n.Host = h
	n.DHT = kdht
	n.PubSub = ps
	n.pubTopic = topic
	n.pubSubSub = sub

	// register stream handlers
	h.SetStreamHandler(FileProtocolID, n.handleFileStream)
	h.SetStreamHandler(MetaProtocolID, n.handleMetaStream)

	// restore local tracks; attach our addrs and announce
	go func() {
		metas, _ := n.storage.AllTrackMetas()
		log.Printf("Start: restoring and announcing %d local tracks", len(metas))
		for _, m := range metas {
			if len(m.ProviderAddrs) == 0 && n.Host != nil {
				m.ProviderAddrs = localAddrs(n.Host)
			}
			if err := n.AnnounceTrack(m); err != nil {
				log.Printf("Start: failed to announce track %s: %v", m.ID, err)
		}
		}
		log.Printf("Start: finished announcing local tracks")
	}()

	// subscribe to pubsub topic and consume messages in background
	go n.runPubSubReader()

	// Start periodic peer discovery and connection
	go n.periodicPeerDiscovery()

	// Evaluate if we should auto-promote to relay (simple heuristic)
	go n.EvaluateRelayRole()

	// mark started
	n.started = true

	// start HTTP API server and remember pointer for graceful shutdown
	srv, err := startHTTPServer(n, n.httpAddr)
	if err != nil {
		// cleanup
		sub.Cancel()
		topic.Close()
		_ = kdht.Close()
		_ = h.Close()
		return err
	}
	n.httpServer = srv

	return nil
}

func (n *CotuneNode) Stop() error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if !n.started {
		return errors.New("not started")
	}

	// cancel context, which should cause background goroutines to stop
	n.cancel()

	// close pubsub subscription & topic
	if n.pubSubSub != nil {
		n.pubSubSub.Cancel()
		n.pubSubSub = nil
	}
	if n.pubTopic != nil {
		n.pubTopic.Close()
		n.pubTopic = nil
	}

	// shutdown http server gracefully
	if n.httpServer != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		_ = n.httpServer.Shutdown(ctx)
		cancel()
		n.httpServer = nil
	}

	if n.DHT != nil {
		_ = n.DHT.Close()
		n.DHT = nil
	}
	if n.Host != nil {
		_ = n.Host.Close()
		n.Host = nil
	}
	if n.storage != nil {
		_ = n.storage.Close()
	}
	n.started = false
	// reset ctx/cancel so new Start can create fresh ones
	n.ctx, n.cancel = context.WithCancel(context.Background())
	return nil
}

func (n *CotuneNode) Status() (*NodeStatus, error) {
	if n.Host == nil {
		return &NodeStatus{Running: false, Ts: nowMillis()}, nil
	}
	addrs := []string{}
	pid := n.Host.ID().String()
	for _, a := range n.Host.Addrs() {
		addrs = append(addrs, a.String()+"/p2p/"+pid)
	}
	var tcount int
	if metas, err := n.storage.AllTrackMetas(); err == nil {
		tcount = len(metas)
	}
	return &NodeStatus{
		PeerID: pid, Addrs: addrs, Running: n.started, Tracks: tcount, Ts: nowMillis(),
	}, nil
}

func (n *CotuneNode) KnownPeers() ([]string, error) {
	mp, err := n.storage.GetKnownPeers()
	if err != nil {
		return nil, err
	}
	out := []string{}
	for pid, addrs := range mp {
		out = append(out, addrs...)
		if len(addrs) == 0 {
			out = append(out, pid)
		}
	}
	return out, nil
}

func (n *CotuneNode) AnnounceTrack(m *TrackMeta) error {
	log.Printf("AnnounceTrack: announcing track id=%s, title=%s, artist=%s", m.ID, m.Title, m.Artist)
	// attach our local addrs
	if n.Host != nil {
		m.ProviderAddrs = localAddrs(n.Host)
		log.Printf("AnnounceTrack: attached %d provider addrs", len(m.ProviderAddrs))
	}

	var firstErr error

	// publish via topic (reuse single topic)
	if n.pubTopic != nil {
		n.publishMu.Lock()
		data := mustJsonMarshal(m)
		log.Printf("AnnounceTrack: publishing to pubsub topic, data size=%d bytes", len(data))
		if err := n.pubTopic.Publish(n.ctx, data); err != nil {
			// не фатально, но логируем и сохраним ошибку
			log.Printf("AnnounceTrack: pubsub publish err: %v", err)
			if firstErr == nil {
				firstErr = err
			}
		} else {
			// Log how many peers are in the topic
			if n.pubTopic != nil {
				peers := n.pubTopic.ListPeers()
				log.Printf("AnnounceTrack: successfully published to pubsub, topic has %d peers", len(peers))
				if len(peers) > 0 {
					for _, p := range peers {
						log.Printf("AnnounceTrack: topic peer: %s", p.String())
					}
				}
			}
		}
		n.publishMu.Unlock()
	} else {
		log.Printf("AnnounceTrack: WARNING - pubTopic is nil, cannot publish to pubsub")
	}

	// Provide on DHT
	// DHT.Provide will automatically publish our addresses from peerstore
	// Make sure relay addresses are in peerstore before providing
	if n.DHT != nil {
		if c, err := makeCIDFromTrackID(m.ID); err == nil {
			// Log addresses that will be published
			if n.Host != nil {
				selfAddrs := n.Host.Peerstore().Addrs(n.Host.ID())
				log.Printf("AnnounceTrack: providing to DHT with %d addresses in peerstore", len(selfAddrs))
				for _, a := range selfAddrs {
					log.Printf("AnnounceTrack: peerstore addr: %s", a.String())
				}
			}
			log.Printf("AnnounceTrack: providing to DHT, CID=%s", c.String())
			if err := n.DHT.Provide(n.ctx, c, true); err != nil {
				log.Printf("AnnounceTrack: dht provide err: %v", err)
				if firstErr == nil {
					firstErr = err
				}
			} else {
				log.Printf("AnnounceTrack: successfully provided to DHT")
			}
			// Note: DHT PutValue requires record validator setup, which is complex.
			// Instead, we rely on PubSub for metadata distribution and stream protocol for retrieval.
		} else {
			log.Printf("AnnounceTrack: makeCIDFromTrackID err: %v", err)
			if firstErr == nil {
				firstErr = err
			}
		}
	} else {
		log.Printf("AnnounceTrack: WARNING - DHT is nil, cannot provide to DHT")
	}

	// save to local storage using merge semantics
	if err := n.storage.MergeAndSaveTrackMeta(m); err != nil {
		log.Printf("AnnounceTrack: storage save err: %v", err)
		if firstErr == nil {
			firstErr = err
		}
	}

	if err := n.storage.SavePeerInfo(m.Owner, m.ProviderAddrs); err != nil {
		log.Printf("AnnounceTrack: save peerinfo err: %v", err)
		if firstErr == nil {
			firstErr = err
		}
	}

	return firstErr
}

// find providers via DHT for a given trackID
func (n *CotuneNode) FindProviders(trackID string, max int) ([]peer.AddrInfo, error) {
	out := []peer.AddrInfo{}
	// 1) быстрый кэш из локального storage (PubSub)
	if cached := n.cachedProvidersFromStorage(trackID); len(cached) > 0 {
		out = append(out, cached...)
		if len(out) >= max && max > 0 {
			return out[:max], nil
		}
	}

	// 2) DHT fallback
	if n.DHT == nil {
		return out, errors.New("dht not ready")
	}
	c, err := makeCIDFromTrackID(trackID)
	if err != nil {
		return out, err
	}
	provCh := n.DHT.FindProvidersAsync(n.ctx, c, max)
	for p := range provCh {
		out = append(out, p)
		_ = NewMaybeSavePeerInfo(n.storage, &p)
	}
	return out, nil
}

// runPubSubReader читает сообщения из подписки topic и сохраняет их в хранилище.
// При получении message пытаемся извлечь ProviderAddrs (если есть) и сохранять.
func (n *CotuneNode) runPubSubReader() {
	if n.pubTopic == nil || n.pubSubSub == nil {
		log.Printf("runPubSubReader: pubTopic or pubSubSub is nil, cannot subscribe")
		return
	}
	log.Printf("runPubSubReader: started, waiting for messages...")
	sub := n.pubSubSub
	msgCount := 0
	for {
		msg, err := sub.Next(n.ctx)
		if err != nil {
			log.Printf("runPubSubReader: subscription ended: %v (processed %d messages)", err, msgCount)
			return
		}
		msgCount++
		if n.Host != nil && msg.ReceivedFrom == n.Host.ID() {
			// ignore our own messages
			log.Printf("runPubSubReader: ignoring own message #%d from %s", msgCount, msg.ReceivedFrom.String())
			continue
		}
		log.Printf("runPubSubReader: received message from peer %s", msg.ReceivedFrom.String())
		var m TrackMeta
		if err := jsonUnmarshal(msg.Data, &m); err == nil {
			log.Printf("runPubSubReader: parsed track meta: id=%s, title=%s, artist=%s", m.ID, m.Title, m.Artist)
			// If provider addrs missing, attach from ReceivedFrom peerstore if available
			if len(m.ProviderAddrs) == 0 {
				// try to pull addrs from peerstore
				if n.Host != nil {
					addrs := n.Host.Peerstore().Addrs(msg.ReceivedFrom)
					for _, a := range addrs {
						m.ProviderAddrs = append(m.ProviderAddrs, a.String()+"/p2p/"+msg.ReceivedFrom.String())
					}
					log.Printf("runPubSubReader: attached %d addrs from peerstore", len(m.ProviderAddrs))
				}
			}
			if err := n.storage.MergeAndSaveTrackMeta(&m); err != nil {
				log.Printf("runPubSubReader: failed to save track meta: %v", err)
			} else {
				log.Printf("runPubSubReader: saved track meta to storage")
			}
			// also save peer info
			_ = n.storage.SavePeerInfo(m.Owner, m.ProviderAddrs)
		} else {
			log.Printf("runPubSubReader: failed to parse message: %v", err)
		}
	}
}

// periodicPeerDiscovery периодически ищет других пиров через DHT и подключается к ним
// для обеспечения работы GossipSub, который требует прямых подключений между пирами
func (n *CotuneNode) periodicPeerDiscovery() {
	ticker := time.NewTicker(30 * time.Second) // каждые 30 секунд
	defer ticker.Stop()

	for {
		select {
		case <-n.ctx.Done():
			return
		case <-ticker.C:
			log.Printf("periodicPeerDiscovery: tick triggered")
			if n.Host == nil || n.DHT == nil {
				log.Printf("periodicPeerDiscovery: Host or DHT is nil, skipping")
				continue
			}

			// Log current connections
			connectedPeers := n.Host.Network().Peers()
			log.Printf("periodicPeerDiscovery: currently connected to %d peers", len(connectedPeers))
			for _, p := range connectedPeers {
				conns := n.Host.Network().ConnsToPeer(p)
				log.Printf("periodicPeerDiscovery: peer %s has %d connections", p.String(), len(conns))
			}

			// Log GossipSub topic peers
			if n.pubTopic != nil {
				topicPeers := n.pubTopic.ListPeers()
				log.Printf("periodicPeerDiscovery: GossipSub topic has %d peers", len(topicPeers))
				for _, p := range topicPeers {
					log.Printf("periodicPeerDiscovery: topic peer: %s", p.String())
				}
			}

			// Try to find other peers by searching for providers of known tracks
			if n.storage != nil {
				metas, err := n.storage.AllTrackMetas()
				if err != nil {
					log.Printf("periodicPeerDiscovery: failed to get track metas: %v", err)
				} else if len(metas) == 0 {
					log.Printf("periodicPeerDiscovery: no tracks in storage, skipping provider search")
				} else {
					log.Printf("periodicPeerDiscovery: found %d tracks in storage, searching for providers...", len(metas))
					// Pick a random track to search for providers
					trackID := metas[0].ID
					log.Printf("periodicPeerDiscovery: searching for providers of track %s", trackID)
					providers, err := n.FindProviders(trackID, 10)
					if err == nil {
						log.Printf("periodicPeerDiscovery: found %d providers for track %s", len(providers), trackID)
						myID := n.Host.ID()
						otherProviders := 0
						for _, pi := range providers {
							// Skip self
							if pi.ID == myID {
								log.Printf("periodicPeerDiscovery: skipping self (provider %s)", pi.ID.String())
								continue
							}
							otherProviders++
							log.Printf("periodicPeerDiscovery: found OTHER provider %s for track %s", pi.ID.String(), trackID)
							// Skip if already connected
							connStatus := n.Host.Network().Connectedness(pi.ID)
							if connStatus == network.Connected {
								log.Printf("periodicPeerDiscovery: already connected to provider %s", pi.ID.String())
								continue
							} else {
								log.Printf("periodicPeerDiscovery: connection status to %s: %v", pi.ID.String(), connStatus)
							}

							// Filter out only localhost addresses (127.0.0.1, ::1) but keep others
							// libp2p AutoRelay will automatically use relay if needed
							filteredAddrs := []multiaddr.Multiaddr{}
							for _, a := range pi.Addrs {
								addrStr := a.String()
								// Only skip localhost loopback addresses
								if strings.Contains(addrStr, "/ip4/127.0.0.1/") || strings.Contains(addrStr, "/ip6/::1/") {
									log.Printf("periodicPeerDiscovery: skipping localhost addr %s for peer %s", addrStr, pi.ID.String())
									continue
								}
								filteredAddrs = append(filteredAddrs, a)
							}

							// If all addresses were localhost, try to connect via relay
							if len(filteredAddrs) == 0 {
								log.Printf("periodicPeerDiscovery: all addresses are localhost for provider %s, trying relay connection", pi.ID.String())
								// Try to connect via relay if we have bootstrap relay
								if len(n.bootstrapAddrs) > 0 {
									relayMA := n.bootstrapAddrs[0]
									relayPI, err := peer.AddrInfoFromP2pAddr(relayMA)
									if err == nil {
										// Ensure we're connected to the relay
										if n.Host.Network().Connectedness(relayPI.ID) != network.Connected {
											log.Printf("periodicPeerDiscovery: connecting to relay %s first", relayPI.ID.String())
											ctxRelay, cancelRelay := context.WithTimeout(n.ctx, 10*time.Second)
											if err := n.Host.Connect(ctxRelay, *relayPI); err != nil {
												log.Printf("periodicPeerDiscovery: failed to connect to relay: %v", err)
												cancelRelay()
												continue
											}
											cancelRelay()
										}
										// Try to reserve a slot on the relay
										if _, err := relayv2client.Reserve(n.ctx, n.Host, *relayPI); err != nil {
											log.Printf("periodicPeerDiscovery: failed to reserve relay slot: %v", err)
										} else {
											log.Printf("periodicPeerDiscovery: reserved relay slot, attempting relay connection to %s", pi.ID.String())
											// Build relay circuit address and add to peerstore
											if relayAddr := n.makeRelayAddr(pi.ID); relayAddr != nil {
												n.Host.Peerstore().AddAddrs(pi.ID, []multiaddr.Multiaddr{relayAddr}, time.Hour)
												pi.Addrs = []multiaddr.Multiaddr{relayAddr}
												log.Printf("periodicPeerDiscovery: added relay circuit addr to peerstore: %s", relayAddr.String())
											}
										}
									}
								}
								// If still no addrs, skip this peer
								if len(pi.Addrs) == 0 {
									log.Printf("periodicPeerDiscovery: no relay addr available for %s, skipping", pi.ID.String())
									continue
								}
							} else {
								pi.Addrs = filteredAddrs
								// Add to peerstore first - this helps AutoRelay find relay paths
								n.Host.Peerstore().AddAddrs(pi.ID, pi.Addrs, time.Hour)
								// Log addresses we're trying to connect to
								for _, a := range pi.Addrs {
									log.Printf("periodicPeerDiscovery: will try addr %s for peer %s", a.String(), pi.ID.String())
								}
							}

							log.Printf("periodicPeerDiscovery: attempting to connect to provider %s with %d addrs", pi.ID.String(), len(pi.Addrs))
							ctx, cancel := context.WithTimeout(n.ctx, 15*time.Second)
							if err := n.Host.Connect(ctx, pi); err != nil {
								log.Printf("periodicPeerDiscovery: failed to connect to %s: %v", pi.ID.String(), err)
								// If connection failed and we have relay addresses, try to reserve a slot first
								// This might help if the target peer also has a reservation
								if len(n.bootstrapAddrs) > 0 {
									for _, relayMA := range n.bootstrapAddrs {
										if relayPI, err := peer.AddrInfoFromP2pAddr(relayMA); err == nil {
											if _, err := relayv2client.Reserve(ctx, n.Host, *relayPI); err == nil {
												log.Printf("periodicPeerDiscovery: reserved relay slot on %s, retrying connection to %s", relayPI.ID.String(), pi.ID.String())
												// Retry connection after reservation
												ctx2, cancel2 := context.WithTimeout(n.ctx, 10*time.Second)
												if err2 := n.Host.Connect(ctx2, pi); err2 == nil {
													log.Printf("periodicPeerDiscovery: successfully connected to %s after relay reservation", pi.ID.String())
													_ = NewMaybeSavePeerInfo(n.storage, &pi)
												} else {
													log.Printf("periodicPeerDiscovery: still failed to connect to %s after reservation: %v", pi.ID.String(), err2)
												}
												cancel2()
											}
										}
									}
								}
							} else {
								log.Printf("periodicPeerDiscovery: successfully connected to provider %s", pi.ID.String())
								_ = NewMaybeSavePeerInfo(n.storage, &pi)
							}
							cancel()
						}
					} else {
						log.Printf("periodicPeerDiscovery: FindProviders error: %v", err)
					}
				}
			}

			// Also try to connect to known peers from storage
			if n.storage != nil {
				knownPeers, err := n.storage.GetKnownPeers()
				if err == nil {
					myID := n.Host.ID()
					for pidStr, addrs := range knownPeers {
						pid, err := peer.Decode(pidStr)
						if err != nil {
							continue
						}
						// Skip self
						if pid == myID {
							continue
						}
						// Skip if already connected
						if n.Host.Network().Connectedness(pid) != 0 {
							continue
						}
						// Skip bootstrap relay
						if pidStr == "12D3KooWPg8PavCBcMzooYYHbnoEN5YttQng3YGABvVwkbM5gvPb" {
							continue
						}

						// Filter addresses: skip only localhost, keep others for AutoRelay
						var pi peer.AddrInfo
						pi.ID = pid
						for _, a := range addrs {
							// Only skip localhost loopback addresses
							if strings.Contains(a, "/ip4/127.0.0.1/") || strings.Contains(a, "/ip6/::1/") {
								continue
							}
							if ma, err := multiaddr.NewMultiaddr(a); err == nil {
								pi.Addrs = append(pi.Addrs, ma)
							}
						}

						// If no usable addrs, add peer to peerstore with empty addrs
						// AutoRelay will try to find a relay path automatically
						if len(pi.Addrs) == 0 {
							log.Printf("periodicPeerDiscovery: no usable addrs for known peer %s, adding to peerstore with empty addrs for AutoRelay", pid.String())
							// Add peer ID to peerstore so AutoRelay knows about it
							n.Host.Peerstore().AddAddrs(pi.ID, []multiaddr.Multiaddr{}, time.Hour)
						} else {
							// Add to peerstore - AutoRelay will handle relay if needed
							n.Host.Peerstore().AddAddrs(pi.ID, pi.Addrs, time.Hour)
						}

						log.Printf("periodicPeerDiscovery: attempting to connect to known peer %s with %d addrs (AutoRelay will handle relay if needed)", pid.String(), len(pi.Addrs))
						ctx, cancel := context.WithTimeout(n.ctx, 15*time.Second)
						if err := n.Host.Connect(ctx, pi); err != nil {
							log.Printf("periodicPeerDiscovery: failed to connect to known peer %s: %v", pid.String(), err)
						} else {
							log.Printf("periodicPeerDiscovery: successfully connected to known peer %s", pid.String())
						}
						cancel()
					}
				}
			}
		}
	}
}

func localAddrs(h host.Host) []string {
	if h == nil {
		return nil
	}
	id := h.ID()
	seen := map[string]struct{}{}
	out := []string{}
	add := func(ma multiaddr.Multiaddr) {
		s := ma.String() + "/p2p/" + id.String()
		if _, ok := seen[s]; ok {
			return
		}
		seen[s] = struct{}{}
		out = append(out, s)
	}
	for _, a := range h.Addrs() {
		add(a)
	}
	// include self addrs from peerstore (may contain relay /p2p-circuit)
	for _, a := range h.Peerstore().Addrs(id) {
		add(a)
	}
	return out
}

// buildRelayCircuitAddr builds /<relay>/p2p-circuit/p2p/<self> multiaddr for advertising
func buildRelayCircuitAddr(relayMA multiaddr.Multiaddr, self peer.ID) multiaddr.Multiaddr {
	circuit, err := multiaddr.NewMultiaddr(fmt.Sprintf("/p2p-circuit/p2p/%s", self.String()))
	if err != nil {
		return nil
	}
	return relayMA.Encapsulate(circuit)
}

// makeRelayAddr builds a relay-circuit multiaddr to reach pid via first known bootstrap relay
func (n *CotuneNode) makeRelayAddr(pid peer.ID) multiaddr.Multiaddr {
	if len(n.bootstrapAddrs) == 0 {
		return nil
	}
	relayMA := n.bootstrapAddrs[0]

	// Extract relay peer ID from the bootstrap address
	relayPI, err := peer.AddrInfoFromP2pAddr(relayMA)
	if err != nil {
		log.Printf("makeRelayAddr: failed to extract relay peer ID from %s: %v", relayMA.String(), err)
		return nil
	}

	// Build the relay circuit address correctly:
	// /ip4/<relay-ip>/tcp/<relay-port>/p2p/<relay-id>/p2p-circuit/p2p/<target-id>
	// We need to get the base address (without /p2p/<relay-id>) and then add both
	baseAddrs := relayPI.Addrs
	if len(baseAddrs) == 0 {
		log.Printf("makeRelayAddr: no base addresses for relay %s", relayPI.ID.String())
		return nil
	}

	// Use the first base address and build the full relay circuit address
	baseAddr := baseAddrs[0]
	relayIDPart, err := multiaddr.NewMultiaddr(fmt.Sprintf("/p2p/%s", relayPI.ID.String()))
	if err != nil {
		return nil
	}
	circuitPart, err := multiaddr.NewMultiaddr(fmt.Sprintf("/p2p-circuit/p2p/%s", pid.String()))
	if err != nil {
		return nil
	}

	// Build: baseAddr + /p2p/<relay-id> + /p2p-circuit/p2p/<target-id>
	result := baseAddr.Encapsulate(relayIDPart).Encapsulate(circuitPart)
	log.Printf("makeRelayAddr: built relay circuit addr for %s: %s", pid.String(), result.String())
	return result
}

// normalizeAddrs - принимает список multiaddr-ов и для тех, которые содержат /p2p/<id>
// возвращает "чистые" адреса (AddrInfo.Addrs-style) — то есть без /p2p/<id> в конце.
// Если addr не содержит /p2p/ — возвращает его как есть.
func normalizeAddrs(addrs []multiaddr.Multiaddr) []multiaddr.Multiaddr {
	out := make([]multiaddr.Multiaddr, 0, len(addrs))

	for _, a := range addrs {
		if pi, err := peer.AddrInfoFromP2pAddr(a); err == nil && pi != nil {
			// pi.Addrs — уже нормализованные адреса
			out = append(out, pi.Addrs...)
		} else {
			out = append(out, a)
		}
	}

	return out
}

// renewRelayReservation periodically renews relay reservation to keep it active
func (n *CotuneNode) renewRelayReservation(relayMA multiaddr.Multiaddr, initialExpiration time.Time) {
	// Renew reservation when it's about to expire (renew at 80% of TTL)
	renewBefore := time.Until(initialExpiration) * 80 / 100
	if renewBefore < 0 {
		renewBefore = 5 * time.Minute // default to 5 minutes if expiration is in the past
	}

	ticker := time.NewTicker(renewBefore)
	defer ticker.Stop()

	for {
		select {
		case <-n.ctx.Done():
			return
		case <-ticker.C:
			// Try to renew reservation
			pi, err := peer.AddrInfoFromP2pAddr(relayMA)
			if err != nil {
				log.Printf("renewRelayReservation: failed to parse relay addr: %v", err)
				return
			}
			res, err := relayv2client.Reserve(n.ctx, n.Host, *pi)
			if err != nil {
				log.Printf("renewRelayReservation: failed to renew reservation with %s: %v", pi.ID.String(), err)
				// Try again in 1 minute
				ticker.Reset(1 * time.Minute)
			} else {
				log.Printf("renewRelayReservation: successfully renewed reservation with %s, expires at %v", pi.ID.String(), res.Expiration)
				// Schedule next renewal at 80% of TTL
				renewBefore = time.Until(res.Expiration) * 80 / 100
				if renewBefore < 1*time.Minute {
					renewBefore = 1 * time.Minute
				}
				ticker.Reset(renewBefore)
			}
		}
	}
}

// EnableRelay attempts to initialize host relay behavior (circuit v2) and AutoRelay is enabled in libp2p options.
func (n *CotuneNode) EnableRelay() error {
	if n.Host == nil {
		return errors.New("host not running")
	}
	r, err := relayv2.New(n.Host)
	if err != nil {
		return fmt.Errorf("relayv2 init failed: %w", err)
	}
	_ = r
	// note: the host was constructed with EnableRelay and EnableAutoRelay,
	// so in many setups this is enough. We return nil on success.
	return nil
}

// EvaluateRelayRole простая эвристика для автоматического включения relay: если у узла есть публичный адрес — включаем relay.
func (n *CotuneNode) EvaluateRelayRole() {
	// простой эвристический пример — если есть хотя бы один non-private ip4 addr, считаем узел подходящим.
	if n.Host == nil {
		return
	}
	addrs := n.Host.Addrs()
	for _, a := range addrs {
		s := a.String()
		if isProbablyPublicMultiaddr(s) {
			_ = n.EnableRelay()
			return
		}
	}
}

// очень простая эвристика: если в multiaddr встречается ip4 и не в RFC1918 — считаем public.
func isProbablyPublicMultiaddr(s string) bool {
	// ищем /ip4/X.Y.Z.W
	if !strings.Contains(s, "/ip4/") {
		return false
	}
	parts := strings.Split(s, "/")
	for i := 0; i < len(parts)-1; i++ {
		if parts[i] == "ip4" {
			ip := parts[i+1]
			if ip == "" {
				return false
			}
			// private prefixes
			if strings.HasPrefix(ip, "10.") {
				return false
			}
			if strings.HasPrefix(ip, "192.168.") {
				return false
			}
			if ip == "127.0.0.1" {
				return false
			}
			// 172.16.0.0 - 172.31.255.255
			if strings.HasPrefix(ip, "172.") {
				partsIP := strings.Split(ip, ".")
				if len(partsIP) >= 2 {
					sec, err := strconv.Atoi(partsIP[1])
					if err == nil {
						if sec >= 16 && sec <= 31 {
							return false
						}
					}
				}
			}
			// otherwise likely public
			return true
		}
	}
	return false
}

func looksRelayOrPublic(a string) bool {
	return strings.Contains(a, "/p2p-circuit") || isProbablyPublicMultiaddr(a)
}

func dedupStrings(in []string) []string {
	m := map[string]struct{}{}
	out := []string{}
	for _, s := range in {
		s = strings.TrimSpace(s)
		if s == "" {
			continue
		}
		if _, ok := m[s]; ok {
			continue
		}
		m[s] = struct{}{}
		out = append(out, s)
	}
	return out
}

// cachedProvidersFromStorage преобразует ProviderAddrs в AddrInfo список.
func (n *CotuneNode) cachedProvidersFromStorage(trackID string) []peer.AddrInfo {
	if n.storage == nil {
		return nil
	}
	m, err := n.storage.GetTrackMeta(trackID)
	if err != nil || m == nil {
		return nil
	}
	out := []peer.AddrInfo{}
	for _, s := range m.ProviderAddrs {
		ma, err := multiaddr.NewMultiaddr(s)
		if err != nil {
			continue
		}
		pi, err := peer.AddrInfoFromP2pAddr(ma)
		if err != nil || pi == nil {
			continue
		}
		out = append(out, *pi)
	}
	return out
}

// RelaySnapshot возвращает список адресов, которые можно отдать в QR/JSON для быстрого подключения.
// Включает собственные addrs + известные адреса, которые выглядят как публичные или relay.
func (n *CotuneNode) RelaySnapshot() []string {
	if n == nil {
		return nil
	}
	out := []string{}
	if st, _ := n.Status(); st != nil {
		out = append(out, st.Addrs...)
	}
	if n.storage != nil {
		if kp, _ := n.storage.GetKnownPeers(); len(kp) > 0 {
			for _, addrs := range kp {
				for _, a := range addrs {
					if looksRelayOrPublic(a) {
						out = append(out, a)
					}
				}
			}
		}
	}
	return dedupStrings(out)
}

// NewMaybeSavePeerInfo - вспомогательная функция: сохранит peer addrs в storage.
// вызывается после успешного подключения к relay
func NewMaybeSavePeerInfo(s *Storage, pi *peer.AddrInfo) error {
	if s == nil || pi == nil {
		return nil
	}
	strAddrs := []string{}
	for _, a := range pi.Addrs {
		sa := a.String()
		if !strings.Contains(sa, "/p2p/") {
			sa = sa + "/p2p/" + pi.ID.String()
		}
		strAddrs = append(strAddrs, sa)
	}
	return s.SavePeerInfo(pi.ID.String(), strAddrs)
}

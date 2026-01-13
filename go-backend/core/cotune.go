package core

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"sync"
)

var startMu sync.RWMutex

// StartNode starts the P2P node and http API. Returns "ok" or error.
func StartNode(httpHostPort string, listen string, relaysCSV string, basePath string) (string, error) {
	// Quick check under read-lock whether node already running
	startMu.RLock()
	if globalNode != nil {
		if st, _ := globalNode.Status(); st != nil && st.Running {
			startMu.RUnlock()
			return "already", nil
		}
	}
	startMu.RUnlock()

	// validate httpHostPort
	if !strings.Contains(httpHostPort, ":") {
		return "", fmt.Errorf("http must be host:port")
	}
	// if scheme included, strip
	httpHostPort = strings.TrimSpace(httpHostPort)
	httpHostPort = strings.TrimPrefix(httpHostPort, "http://")
	httpHostPort = strings.TrimPrefix(httpHostPort, "https://")
	httpAddr := httpHostPort

	// basePath for storage, if empty use ./cotune_data
	if basePath == "" {
		basePath = "./cotune_data"
	}

	// Create node (this may take time) WITHOUT holding startMu
	log.Printf("StartNode: creating node with basePath=%s, httpAddr=%s", basePath, httpAddr)
	n, err := NewCotuneNode(basePath, httpAddr)
	if err != nil {
		log.Printf("StartNode: NewCotuneNode failed: %v", err)
		return "", err
	}

	// parse relaysCSV
	relays := []string{}
	if relaysCSV != "" {
		for _, r := range strings.Split(relaysCSV, ",") {
			if strings.TrimSpace(r) != "" {
				relays = append(relays, strings.TrimSpace(r))
			}
		}
	}

	// Try to start node (network ops) — still without global lock
	log.Printf("StartNode: starting node with listen=%s, relays=%v", listen, relays)
	if err := n.Start(listen, relays); err != nil {
		log.Printf("StartNode: node.Start failed: %v", err)
		_ = n.storage.Close()
		return "", err
	}
	log.Printf("StartNode: node started successfully")

	// Now set globalNode under write lock, but check again if another concurrent starter set it.
	startMu.Lock()
	defer startMu.Unlock()
	if globalNode != nil {
		// another goroutine started the node while we were starting ours
		// in that case stop what we started and return "already"
		_ = n.Stop()
		_ = n.storage.Close()
		return "already", nil
	}
	globalNode = n
	return "ok", nil
}

func StopNode() (string, error) {
	startMu.Lock()
	defer startMu.Unlock()
	if globalNode == nil {
		return "notrunning", nil
	}
	if err := globalNode.Stop(); err != nil {
		return "", err
	}
	// close storage to release DB file handles
	if globalNode.storage != nil {
		_ = globalNode.storage.Close()
	}
	globalNode = nil
	return "stopped", nil
}

func Status() (string, error) {
	startMu.RLock()
	gn := globalNode
	startMu.RUnlock()
	if gn == nil {
		s := &NodeStatus{Running: false, Ts: nowMillis()}
		b, _ := json.Marshal(s)
		return string(b), nil
	}
	st, _ := gn.Status()
	b, _ := json.Marshal(st)
	return string(b), nil
}

func GetPeerInfoJson() (string, error) {
	startMu.RLock()
	gn := globalNode
	startMu.RUnlock()
	if gn == nil {
		return "", fmt.Errorf("node not started")
	}
	st, _ := gn.Status()
	out := map[string]any{
		"peerId": st.PeerID,
		"addrs":  st.Addrs,
		"relays": gn.RelaySnapshot(),
		"ts":     nowMillis(),
	}
	b, _ := json.Marshal(out)
	return string(b), nil
}

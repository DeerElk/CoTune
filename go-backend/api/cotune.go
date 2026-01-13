package cotune

import (
	"sync"

	"github.com/DeerElk/CoTune/go-backend/core"
)

// Глобальная защита для gomobile вызовов
var mu sync.Mutex

// StartNode запускает Cotune-ноду.
// Все параметры — строки (совместимо с gomobile).
//
// httpAddr   — "127.0.0.1:7777"
// listen     — "/ip4/0.0.0.0/tcp/0"
// relaysCSV  — CSV строка с relay multiaddr
// basePath   — путь к данным (Android files dir)
//
// Возвращает: "ok", "already" или "error: ..."
func StartNode(httpAddr string, listen string, relaysCSV string, basePath string) string {
	mu.Lock()
	defer mu.Unlock()

	res, err := core.StartNode(httpAddr, listen, relaysCSV, basePath)
	if err != nil {
		return "error: " + err.Error()
	}
	return res
}

// StopNode останавливает ноду
func StopNode() string {
	mu.Lock()
	defer mu.Unlock()

	res, err := core.StopNode()
	if err != nil {
		return "error: " + err.Error()
	}
	return res
}

// Status возвращает JSON-строку NodeStatus
func Status() string {
	mu.Lock()
	defer mu.Unlock()

	s, err := core.Status()
	if err != nil {
		return `{"running":false,"error":"` + err.Error() + `"}`
	}
	return s
}

// GetPeerInfoJson возвращает JSON с peerId / addrs / relays
func GetPeerInfoJson() string {
	mu.Lock()
	defer mu.Unlock()

	s, err := core.GetPeerInfoJson()
	if err != nil {
		return "{}"
	}
	return s
}
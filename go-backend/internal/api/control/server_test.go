package control

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHandlersRejectWrongMethodsBeforeDaemonUse(t *testing.T) {
	s := New("127.0.0.1:0", nil, nil, nil)

	tests := []struct {
		name    string
		handler http.HandlerFunc
		method  string
		path    string
	}{
		{name: "status", handler: s.handleStatus, method: http.MethodPost, path: "/status"},
		{name: "peers", handler: s.handlePeers, method: http.MethodPost, path: "/peers"},
		{name: "addTrack", handler: s.handleAddTrack, method: http.MethodGet, path: "/addTrack"},
		{name: "search", handler: s.handleSearch, method: http.MethodGet, path: "/search"},
		{name: "connect", handler: s.handleConnect, method: http.MethodGet, path: "/connect"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			rr := httptest.NewRecorder()

			tc.handler(rr, req)

			if rr.Code != http.StatusMethodNotAllowed {
				t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusMethodNotAllowed, rr.Body.String())
			}
			assertJSONError(t, rr.Body.String(), http.StatusMethodNotAllowed)
		})
	}
}

func TestAddTrackRejectsInvalidBodyBeforeDaemonUse(t *testing.T) {
	s := New("127.0.0.1:0", nil, nil, nil)

	req := httptest.NewRequest(http.MethodPost, "/addTrack", strings.NewReader("{"))
	rr := httptest.NewRecorder()

	s.handleAddTrack(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
	assertJSONError(t, rr.Body.String(), http.StatusBadRequest)
}

func TestSearchRejectsEmptyQueryBeforeDaemonUse(t *testing.T) {
	s := New("127.0.0.1:0", nil, nil, nil)

	req := httptest.NewRequest(http.MethodPost, "/search", strings.NewReader(`{"query":""}`))
	rr := httptest.NewRecorder()

	s.handleSearch(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
	assertJSONError(t, rr.Body.String(), http.StatusBadRequest)
}

func TestConnectRejectsMissingPeerDataBeforeDaemonUse(t *testing.T) {
	s := New("127.0.0.1:0", nil, nil, nil)

	req := httptest.NewRequest(http.MethodPost, "/connect", strings.NewReader(`{"peer_id":"peer"}`))
	rr := httptest.NewRecorder()

	s.handleConnect(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
	assertJSONError(t, rr.Body.String(), http.StatusBadRequest)
}

func assertJSONError(t *testing.T, body string, status int) {
	t.Helper()
	var payload struct {
		Error   string `json:"error"`
		Status  int    `json:"status"`
		Success bool   `json:"success"`
	}
	if err := json.Unmarshal([]byte(body), &payload); err != nil {
		t.Fatalf("response is not JSON: %v; body=%s", err, body)
	}
	if payload.Error == "" {
		t.Fatalf("error field is empty: %+v", payload)
	}
	if payload.Status != status {
		t.Fatalf("status field = %d, want %d", payload.Status, status)
	}
	if payload.Success {
		t.Fatalf("success field = true, want false")
	}
}

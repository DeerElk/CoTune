package dht

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"testing"
)

func TestHashTokenReturnsStableSHA256Hex(t *testing.T) {
	token := "cotune search token"
	got := HashToken(token)
	wantBytes := sha256.Sum256([]byte(token))
	want := hex.EncodeToString(wantBytes[:])

	if got != want {
		t.Fatalf("HashToken() = %q, want %q", got, want)
	}
	if len(got) != 64 {
		t.Fatalf("HashToken() length = %d, want 64", len(got))
	}
}

func TestCTIDToCIDAcceptsValidSHA256Hex(t *testing.T) {
	ctid := strings.Repeat("a", 64)

	got, err := ctidToCID(ctid)
	if err != nil {
		t.Fatalf("ctidToCID() returned error: %v", err)
	}
	if !got.Defined() {
		t.Fatal("ctidToCID() returned undefined CID")
	}
}

func TestCTIDToCIDRejectsInvalidValues(t *testing.T) {
	tests := []string{
		"not-hex",
		strings.Repeat("a", 62),
		strings.Repeat("a", 66),
	}

	for _, tc := range tests {
		if _, err := ctidToCID(tc); err == nil {
			t.Fatalf("ctidToCID(%q) returned nil error", tc)
		}
	}
}

func TestTokenHashToCIDRejectsInvalidValues(t *testing.T) {
	tests := []string{
		"not-hex",
		strings.Repeat("b", 2),
	}

	for _, tc := range tests {
		if _, err := tokenHashToCID(tc); err == nil {
			t.Fatalf("tokenHashToCID(%q) returned nil error", tc)
		}
	}
}

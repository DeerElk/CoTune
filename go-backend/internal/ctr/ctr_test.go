package ctr

import (
	"encoding/hex"
	"testing"
)

func TestNormalizePCMUsesLittleEndianBytes(t *testing.T) {
	pcm := []int16{0x1234, -2, 0}

	got := normalizePCM(pcm)
	wantHex := "3412feff0000"
	if hex.EncodeToString(got) != wantHex {
		t.Fatalf("normalizePCM() = %s, want %s", hex.EncodeToString(got), wantHex)
	}
}

func TestNormalizePCMEmptyInput(t *testing.T) {
	got := normalizePCM(nil)
	if len(got) != 0 {
		t.Fatalf("normalizePCM(nil) length = %d, want 0", len(got))
	}
}

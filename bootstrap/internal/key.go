package internal

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"

	"github.com/libp2p/go-libp2p/core/crypto"
)

const defaultKeyFileName = "bootstrap.key"

// loadOrGenerateKey loads an existing private key from file, or generates a new one
// and saves it. This ensures the bootstrap peer has a stable peer ID across restarts.
func loadOrGenerateKey(keyPath string) (crypto.PrivKey, error) {
	// If keyPath is empty, use default filename in current directory
	if keyPath == "" {
		keyPath = defaultKeyFileName
	}

	// Expand path (handle ~, relative paths, etc.)
	keyPath, err := filepath.Abs(keyPath)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve key path: %w", err)
	}

	// Try to load existing key
	if data, err := os.ReadFile(keyPath); err == nil {
		keyBytes, err := hex.DecodeString(string(data))
		if err != nil {
			return nil, fmt.Errorf("failed to decode key from %s: %w", keyPath, err)
		}

		privKey, err := crypto.UnmarshalPrivateKey(keyBytes)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal key from %s: %w", keyPath, err)
		}

		return privKey, nil
	}

	// Generate new key
	privKey, _, err := crypto.GenerateEd25519Key(rand.Reader)
	if err != nil {
		return nil, fmt.Errorf("failed to generate key: %w", err)
	}

	// Save key
	keyBytes, err := crypto.MarshalPrivateKey(privKey)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal key: %w", err)
	}

	// Ensure directory exists
	keyDir := filepath.Dir(keyPath)
	if err := os.MkdirAll(keyDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create key directory: %w", err)
	}

	// Write key file with restrictive permissions (owner read/write only)
	if err := os.WriteFile(keyPath, []byte(hex.EncodeToString(keyBytes)), 0600); err != nil {
		return nil, fmt.Errorf("failed to save key to %s: %w", keyPath, err)
	}

	return privKey, nil
}

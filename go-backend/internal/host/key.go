package host

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"

	"github.com/libp2p/go-libp2p/core/crypto"
)

const keyFileName = "private.key"

func loadOrGenerateKey(dataDir string) (crypto.PrivKey, error) {
	keyPath := filepath.Join(dataDir, keyFileName)

	// Try to load existing key
	if data, err := os.ReadFile(keyPath); err == nil {
		keyBytes, err := hex.DecodeString(string(data))
		if err != nil {
			return nil, fmt.Errorf("failed to decode key: %w", err)
		}

		privKey, err := crypto.UnmarshalPrivateKey(keyBytes)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal key: %w", err)
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

	if err := os.WriteFile(keyPath, []byte(hex.EncodeToString(keyBytes)), 0600); err != nil {
		return nil, fmt.Errorf("failed to save key: %w", err)
	}

	return privKey, nil
}

package dht

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"

	"github.com/ipfs/go-cid"
	"github.com/multiformats/go-multihash"
)

const (
	// CTIDNamespace is the namespace prefix for CTID in DHT
	CTIDNamespace = "/ctid/"
	// TokenNamespace is the namespace prefix for tokens in DHT
	TokenNamespace = "/token/"
)

// ctidToCID converts a CTID (hex string) to a CID
func ctidToCID(ctid string) (cid.Cid, error) {
	// CTID is already a SHA256 hash, we just need to wrap it
	hashBytes, err := hex.DecodeString(ctid)
	if err != nil {
		return cid.Undef, fmt.Errorf("invalid CTID hex: %w", err)
	}

	if len(hashBytes) != 32 {
		return cid.Undef, fmt.Errorf("CTID must be 32 bytes (SHA256)")
	}

	// Create multihash
	mh, err := multihash.Encode(hashBytes, multihash.SHA2_256)
	if err != nil {
		return cid.Undef, fmt.Errorf("failed to encode multihash: %w", err)
	}

	// Create CID v1 with raw codec
	return cid.NewCidV1(cid.Raw, mh), nil
}

// tokenHashToCID converts a token hash to a CID
func tokenHashToCID(tokenHash string) (cid.Cid, error) {
	// Token hash is SHA256 of the token
	hashBytes, err := hex.DecodeString(tokenHash)
	if err != nil {
		return cid.Undef, fmt.Errorf("invalid token hash hex: %w", err)
	}

	if len(hashBytes) != 32 {
		return cid.Undef, fmt.Errorf("token hash must be 32 bytes (SHA256)")
	}

	mh, err := multihash.Encode(hashBytes, multihash.SHA2_256)
	if err != nil {
		return cid.Undef, fmt.Errorf("failed to encode multihash: %w", err)
	}

	return cid.NewCidV1(cid.Raw, mh), nil
}

// HashToken hashes a token string to a hex string
func HashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

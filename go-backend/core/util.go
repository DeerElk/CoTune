package core

import (
	"crypto/sha256"
	"time"

	cid "github.com/ipfs/go-cid"
	multihash "github.com/multiformats/go-multihash"
)

func makeCIDFromTrackID(trackID string) (cid.Cid, error) {
	h := sha256.Sum256([]byte(trackID))
	mh, err := multihash.Encode(h[:], multihash.SHA2_256)
	if err != nil {
		return cid.Cid{}, err
	}
	c := cid.NewCidV1(cid.Raw, mh)
	return c, nil
}

func nowMillis() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
}

// firstNonEmpty returns the first non-empty string among args, or empty string if all are empty.
func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}

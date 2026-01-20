package models

// Track represents a music track
type Track struct {
	ID         string `json:"id"`
	CTID       string `json:"ctid"` // Canonical Track ID (SHA256 of normalized PCM)
	Title      string `json:"title"`
	Artist     string `json:"artist"`
	Path       string `json:"path"`               // Local file path
	Liked      bool   `json:"liked"`              // User liked this track
	Recognized bool   `json:"recognized"`         // User has entered title/artist
	Checksum   string `json:"checksum,omitempty"` // Legacy MD5 checksum (deprecated, use CTID)
}

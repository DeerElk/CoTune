package core

type TrackMeta struct {
	ID            string   `json:"id"`
	Title         string   `json:"title"`
	Artist        string   `json:"artist"`
	Owner         string   `json:"owner"`
	Path          string   `json:"path,omitempty"`
	Recognized    bool     `json:"recognized"`
	Checksum      string   `json:"checksum,omitempty"`
	Size          int64    `json:"size,omitempty"`
	Ts            int64    `json:"ts"`
	ProviderAddrs []string `json:"addrs,omitempty"`
}

type NodeStatus struct {
	PeerID  string   `json:"peerId"`
	Addrs   []string `json:"addrs"`
	Running bool     `json:"running"`
	Tracks  int      `json:"tracks"`
	Ts      int64    `json:"ts"`
}

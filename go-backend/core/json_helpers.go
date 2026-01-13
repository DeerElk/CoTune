package core

import "encoding/json"

func mustJsonMarshal(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

func jsonUnmarshal(b []byte, v any) error {
	return json.Unmarshal(b, v)
}

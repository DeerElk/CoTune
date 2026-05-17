package search

import (
	"testing"

	"github.com/cotune/go-backend/internal/models"
	"github.com/cotune/go-backend/internal/storage"
)

func newTestService(t *testing.T) (*Service, func()) {
	t.Helper()
	store, err := storage.New(t.TempDir())
	if err != nil {
		t.Fatalf("storage.New() error: %v", err)
	}
	svc := &Service{
		store:      store,
		localIndex: make(map[string][]string),
	}
	return svc, func() {
		if err := store.Close(); err != nil {
			t.Fatalf("store.Close() error: %v", err)
		}
	}
}

func TestTokenizeNormalizesPunctuationAndShortTokens(t *testing.T) {
	svc, cleanup := newTestService(t)
	defer cleanup()

	got := svc.Tokenize("A Night-Drive, by DJ_Q!")
	want := []string{"night", "drive", "by", "dj"}
	if len(got) != len(want) {
		t.Fatalf("Tokenize() = %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("Tokenize()[%d] = %q, want %q", i, got[i], want[i])
		}
	}
}

func TestSearchLocalSkipsTracksWithoutCTID(t *testing.T) {
	svc, cleanup := newTestService(t)
	defer cleanup()

	withCTID := &models.Track{
		ID:         "with-ctid",
		CTID:       "ctid-123",
		Title:      "Local Song",
		Artist:     "Tester",
		Recognized: true,
	}
	withoutCTID := &models.Track{
		ID:         "without-ctid",
		Title:      "Local Song",
		Artist:     "Tester",
		Recognized: true,
	}
	if err := svc.store.SaveTrack(withCTID); err != nil {
		t.Fatalf("SaveTrack(withCTID) error: %v", err)
	}
	if err := svc.store.SaveTrack(withoutCTID); err != nil {
		t.Fatalf("SaveTrack(withoutCTID) error: %v", err)
	}

	results := svc.searchLocal([]string{"local"})
	if len(results) != 1 {
		t.Fatalf("Search() returned %d results, want 1: %+v", len(results), results)
	}
	if results[0].CTID != withCTID.CTID {
		t.Fatalf("Search() CTID = %q, want %q", results[0].CTID, withCTID.CTID)
	}
}

func TestUpdateLocalIndexDeduplicatesCTID(t *testing.T) {
	svc, cleanup := newTestService(t)
	defer cleanup()

	track := &models.Track{
		ID:         "track-1",
		CTID:       "ctid-1",
		Title:      "Shared Song",
		Artist:     "Shared Artist",
		Recognized: true,
	}

	svc.UpdateLocalIndex(track)
	svc.UpdateLocalIndex(track)

	ctids := svc.localIndex["shared"]
	if len(ctids) != 1 {
		t.Fatalf("localIndex[shared] = %v, want one CTID", ctids)
	}
	if ctids[0] != track.CTID {
		t.Fatalf("localIndex[shared][0] = %q, want %q", ctids[0], track.CTID)
	}
}

func TestUpdateLocalIndexIgnoresUnrecognizedAndEmptyCTID(t *testing.T) {
	svc, cleanup := newTestService(t)
	defer cleanup()

	svc.UpdateLocalIndex(&models.Track{ID: "a", CTID: "", Title: "No CTID", Recognized: true})
	svc.UpdateLocalIndex(&models.Track{ID: "b", CTID: "ctid", Title: "Hidden", Recognized: false})

	if len(svc.localIndex) != 0 {
		t.Fatalf("localIndex = %+v, want empty", svc.localIndex)
	}
}

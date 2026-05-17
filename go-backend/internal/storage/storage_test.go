package storage

import (
	"testing"

	"github.com/cotune/go-backend/internal/models"
)

func TestStorageTrackCRUDSearchAndPersistence(t *testing.T) {
	dir := t.TempDir()
	store, err := New(dir)
	if err != nil {
		t.Fatalf("New() error: %v", err)
	}

	track := &models.Track{
		ID:         "track-1",
		CTID:       "ctid-1",
		Title:      "Night Drive",
		Artist:     "CoTune Artist",
		Path:       "C:/music/night-drive.wav",
		Liked:      true,
		Recognized: true,
	}
	if err := store.SaveTrack(track); err != nil {
		t.Fatalf("SaveTrack() error: %v", err)
	}

	got, err := store.GetTrack(track.ID)
	if err != nil {
		t.Fatalf("GetTrack() error: %v", err)
	}
	if got.Title != track.Title || got.Artist != track.Artist || got.CTID != track.CTID {
		t.Fatalf("GetTrack() = %+v, want %+v", got, track)
	}

	byCTID, err := store.FindTrackByCTID(track.CTID)
	if err != nil {
		t.Fatalf("FindTrackByCTID() error: %v", err)
	}
	if byCTID.ID != track.ID {
		t.Fatalf("FindTrackByCTID() ID = %q, want %q", byCTID.ID, track.ID)
	}

	byTitle, err := store.FindTracksByToken("drive")
	if err != nil {
		t.Fatalf("FindTracksByToken(title) error: %v", err)
	}
	if len(byTitle) != 1 || byTitle[0].ID != track.ID {
		t.Fatalf("FindTracksByToken(title) = %+v, want track %q", byTitle, track.ID)
	}

	byArtist, err := store.FindTracksByToken("artist")
	if err != nil {
		t.Fatalf("FindTracksByToken(artist) error: %v", err)
	}
	if len(byArtist) != 1 || byArtist[0].ID != track.ID {
		t.Fatalf("FindTracksByToken(artist) = %+v, want track %q", byArtist, track.ID)
	}

	if err := store.Close(); err != nil {
		t.Fatalf("Close() error: %v", err)
	}

	reopened, err := New(dir)
	if err != nil {
		t.Fatalf("New(reopen) error: %v", err)
	}
	defer reopened.Close()

	persisted, err := reopened.GetTrack(track.ID)
	if err != nil {
		t.Fatalf("GetTrack() after reopen error: %v", err)
	}
	if persisted.CTID != track.CTID {
		t.Fatalf("persisted CTID = %q, want %q", persisted.CTID, track.CTID)
	}

	if err := reopened.DeleteTrack(track.ID); err != nil {
		t.Fatalf("DeleteTrack() error: %v", err)
	}
	if _, err := reopened.GetTrack(track.ID); err == nil {
		t.Fatal("GetTrack() after delete returned nil error")
	}
}

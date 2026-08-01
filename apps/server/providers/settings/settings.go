// Package settings persists server-side configuration (e.g. the OBS
// websocket password) so it's set once on the desktop server rather than
// re-entered on every phone client.
package settings

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
)

// Settings holds every server-configurable value. Add fields here as more
// settings are needed — Store.Update takes a matching pointer per field so
// callers can patch a subset without touching the others.
type Settings struct {
	ObsPassword string `json:"obsPassword"`
}

// Update describes a partial change to Settings. A nil field is left
// untouched; a non-nil field (including an empty string, which clears it) is
// applied.
type Update struct {
	ObsPassword *string
}

type Store struct {
	mu      sync.RWMutex
	path    string
	current Settings
}

// NewStore loads settings from the standard per-user config location,
// tolerating a missing file (first run) or a corrupt one (logged by the
// caller) by starting from zero-value defaults either way.
func NewStore() (*Store, error) {
	return NewStoreAt(defaultPath())
}

func defaultPath() string {
	dir, err := os.UserConfigDir()
	if err != nil {
		dir = "."
	}
	return filepath.Join(dir, "open-control", "settings.json")
}

// NewStoreAt loads (or initializes) a store backed by the given file path.
// Exposed for tests that need an isolated, temp-dir-backed store.
func NewStoreAt(path string) (*Store, error) {
	s := &Store{path: path}

	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return s, nil
	}
	if err != nil {
		return s, err
	}

	if err := json.Unmarshal(data, &s.current); err != nil {
		return s, err
	}
	return s, nil
}

func (s *Store) ObsPassword() string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.current.ObsPassword
}

func (s *Store) HasObsPassword() bool {
	return s.ObsPassword() != ""
}

// Update applies u's non-nil fields and persists the result to disk.
func (s *Store) Update(u Update) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if u.ObsPassword != nil {
		s.current.ObsPassword = *u.ObsPassword
	}

	if err := os.MkdirAll(filepath.Dir(s.path), 0o700); err != nil {
		return err
	}

	data, err := json.Marshal(s.current)
	if err != nil {
		return err
	}

	return os.WriteFile(s.path, data, 0o600)
}

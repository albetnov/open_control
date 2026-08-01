package settings

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	fiber "github.com/gofiber/fiber/v3"
)

func decodeJSON(t *testing.T, r *http.Response) map[string]any {
	t.Helper()
	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	return body
}

func TestStoreRoundTrip(t *testing.T) {
	path := filepath.Join(t.TempDir(), "settings.json")

	store, err := NewStoreAt(path)
	if err != nil {
		t.Fatal(err)
	}
	if store.HasObsPassword() {
		t.Fatal("expected no password on a fresh store")
	}

	password := "hunter2"
	if err := store.Update(Update{ObsPassword: &password}); err != nil {
		t.Fatal(err)
	}

	reloaded, err := NewStoreAt(path)
	if err != nil {
		t.Fatal(err)
	}
	if reloaded.ObsPassword() != password {
		t.Fatalf("expected %q, got %q", password, reloaded.ObsPassword())
	}
}

func TestStoreMissingFileStartsWithDefaults(t *testing.T) {
	path := filepath.Join(t.TempDir(), "does-not-exist.json")

	store, err := NewStoreAt(path)
	if err != nil {
		t.Fatal(err)
	}
	if store.HasObsPassword() {
		t.Fatal("expected no password when no file exists yet")
	}
}

func TestHandlersPutThenGet(t *testing.T) {
	path := filepath.Join(t.TempDir(), "settings.json")
	store, err := NewStoreAt(path)
	if err != nil {
		t.Fatal(err)
	}

	app := fiber.New()
	RegisterRoutes(app, store)

	put := func(body string) map[string]any {
		t.Helper()
		req := httptest.NewRequest(http.MethodPut, "/settings", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		resp, err := app.Test(req)
		if err != nil {
			t.Fatal(err)
		}
		defer resp.Body.Close()
		return decodeJSON(t, resp)
	}

	got := put(`{"obsPassword": "hunter2"}`)
	if got["obsPasswordSet"] != true {
		t.Fatalf("expected obsPasswordSet=true after setting a password, got %v", got)
	}

	getReq := httptest.NewRequest(http.MethodGet, "/settings", nil)
	getResp, err := app.Test(getReq)
	if err != nil {
		t.Fatal(err)
	}
	defer getResp.Body.Close()
	got = decodeJSON(t, getResp)
	if got["obsPasswordSet"] != true {
		t.Fatalf("expected obsPasswordSet=true on GET, got %v", got)
	}
	if _, leaked := got["obsPassword"]; leaked {
		t.Fatal("GET must never return the raw password")
	}

	got = put(`{"obsPassword": ""}`)
	if got["obsPasswordSet"] != false {
		t.Fatalf("expected obsPasswordSet=false after clearing, got %v", got)
	}
}

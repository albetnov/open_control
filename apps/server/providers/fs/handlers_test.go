package fs

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	fiber "github.com/gofiber/fiber/v3"

	"open_control_server/providers/settings"
)

func newTestApp(t *testing.T, root string) *fiber.App {
	t.Helper()

	store, err := settings.NewStoreAt(filepath.Join(t.TempDir(), "settings.json"))
	if err != nil {
		t.Fatal(err)
	}
	if root != "" {
		if err := store.Update(settings.Update{FsRoot: &root}); err != nil {
			t.Fatal(err)
		}
	}

	app := fiber.New()
	RegisterRoutes(app, store, &Pool{})
	return app
}

func decodeBody(t *testing.T, resp *http.Response) map[string]any {
	t.Helper()
	var body map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	return body
}

func TestFsRootNotConfiguredReturnsConflict(t *testing.T) {
	app := newTestApp(t, "")

	resp, err := app.Test(httptest.NewRequest(http.MethodGet, "/fs/list", nil))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusConflict {
		t.Fatalf("expected 409, got %d", resp.StatusCode)
	}
}

func TestListReflectsLiveDisk(t *testing.T) {
	root := t.TempDir()
	write(t, root, "clip.mp4")
	app := newTestApp(t, root)

	resp, err := app.Test(httptest.NewRequest(http.MethodGet, "/fs/list", nil))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	var entries []entry
	if err := json.NewDecoder(resp.Body).Decode(&entries); err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 || entries[0].Name != "clip.mp4" {
		t.Fatalf("expected clip.mp4 listed, got %+v", entries)
	}
}

func TestPoolQueueAndSubmitEndToEnd(t *testing.T) {
	root := t.TempDir()
	write(t, root, "old.mp4")
	app := newTestApp(t, root)

	queueReq := httptest.NewRequest(
		http.MethodPost,
		"/fs/pool",
		bytes.NewReader([]byte(`{"type":"rename","path":"old.mp4","newPath":"new.mp4"}`)),
	)
	queueReq.Header.Set("Content-Type", "application/json")
	queueResp, err := app.Test(queueReq)
	if err != nil {
		t.Fatal(err)
	}
	defer queueResp.Body.Close()
	if queueResp.StatusCode != http.StatusOK {
		t.Fatalf("expected queueing to succeed, got %d", queueResp.StatusCode)
	}

	listResp, err := app.Test(httptest.NewRequest(http.MethodGet, "/fs/pool", nil))
	if err != nil {
		t.Fatal(err)
	}
	defer listResp.Body.Close()
	var queued []PoolOp
	if err := json.NewDecoder(listResp.Body).Decode(&queued); err != nil {
		t.Fatal(err)
	}
	if len(queued) != 1 {
		t.Fatalf("expected one queued op, got %+v", queued)
	}

	if _, err := os.Stat(filepath.Join(root, "new.mp4")); err == nil {
		t.Fatal("rename must not be applied before submit")
	}

	submitResp, err := app.Test(httptest.NewRequest(http.MethodPost, "/fs/submit", nil))
	if err != nil {
		t.Fatal(err)
	}
	defer submitResp.Body.Close()
	result := decodeBody(t, submitResp)
	if succeeded, _ := result["succeeded"].([]any); len(succeeded) != 1 {
		t.Fatalf("expected submit to succeed, got %+v", result)
	}

	if _, err := os.Stat(filepath.Join(root, "new.mp4")); err != nil {
		t.Fatal("expected rename to be applied after submit")
	}
}

func TestPoolRejectsPathTraversal(t *testing.T) {
	root := t.TempDir()
	app := newTestApp(t, root)

	req := httptest.NewRequest(
		http.MethodPost,
		"/fs/pool",
		strings.NewReader(`{"type":"delete","path":"../../etc/passwd"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

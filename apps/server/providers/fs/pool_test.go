package fs

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPoolSubmitHappyPath(t *testing.T) {
	root := t.TempDir()
	write(t, root, "a.txt")
	write(t, root, "b.txt")

	pool := &Pool{}
	pool.Add(PoolOp{Type: OpRename, Path: "a.txt", NewPath: "a2.txt"})
	pool.Add(PoolOp{Type: OpDelete, Path: "b.txt"})

	result := pool.Submit(root)

	if len(result.Succeeded) != 2 {
		t.Fatalf("expected 2 succeeded ops, got %+v", result)
	}
	if result.Failed != nil {
		t.Fatalf("expected no failure, got %+v", result.Failed)
	}
	if len(pool.List()) != 0 {
		t.Fatalf("expected pool to be drained, got %+v", pool.List())
	}

	assertExists(t, filepath.Join(root, "a2.txt"), true)
	assertExists(t, filepath.Join(root, "a.txt"), false)
	assertExists(t, filepath.Join(root, "b.txt"), false)
}

func TestPoolSubmitStopsAtFailureLeavesRemainder(t *testing.T) {
	root := t.TempDir()
	write(t, root, "a.txt")

	pool := &Pool{}
	pool.Add(PoolOp{Type: OpRename, Path: "a.txt", NewPath: "a2.txt"})      // succeeds
	pool.Add(PoolOp{Type: OpRename, Path: "missing.txt", NewPath: "x.txt"}) // fails: no such source
	pool.Add(PoolOp{Type: OpDelete, Path: "a2.txt"})                        // never attempted

	result := pool.Submit(root)

	if len(result.Succeeded) != 1 || result.Succeeded[0].Path != "a.txt" {
		t.Fatalf("expected exactly the rename to succeed, got %+v", result.Succeeded)
	}
	if result.Failed == nil || result.Failed.Path != "missing.txt" {
		t.Fatalf("expected the rename of missing.txt to be reported failed, got %+v", result.Failed)
	}
	if len(result.Remaining) != 1 || result.Remaining[0].Path != "a2.txt" {
		t.Fatalf("expected the delete to remain queued, got %+v", result.Remaining)
	}

	remaining := pool.List()
	if len(remaining) != 2 {
		t.Fatalf("expected failed op + remainder still queued for retry, got %+v", remaining)
	}
	if remaining[0].Path != "missing.txt" || remaining[1].Path != "a2.txt" {
		t.Fatalf("unexpected queued ops after failure: %+v", remaining)
	}

	assertExists(t, filepath.Join(root, "a2.txt"), true)
}

func write(t *testing.T, root, name string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(root, name), []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
}

func assertExists(t *testing.T, path string, want bool) {
	t.Helper()
	_, err := os.Stat(path)
	got := err == nil
	if got != want {
		t.Fatalf("expected exists(%s)=%v, got %v (err=%v)", path, want, got, err)
	}
}

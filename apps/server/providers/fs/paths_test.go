package fs

import (
	"strings"
	"testing"
)

func TestResolveNeutralizesTraversal(t *testing.T) {
	// The leading-separator + Clean trick makes "../../etc/passwd" resolve to
	// a harmless path still inside root, rather than needing to detect and
	// reject it after the fact - verify it actually stays contained.
	got, err := Resolve("/srv/media", "../../etc/passwd")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(got, "/srv/media/") {
		t.Fatalf("expected traversal to stay contained under root, got %q", got)
	}
}

func TestResolveJoinsWithinRoot(t *testing.T) {
	got, err := Resolve("/srv/media", "clips/one.mp4")
	if err != nil {
		t.Fatal(err)
	}
	want := "/srv/media/clips/one.mp4"
	if got != want {
		t.Fatalf("expected %q, got %q", want, got)
	}
}

func TestResolveEmptyPathIsRoot(t *testing.T) {
	got, err := Resolve("/srv/media", "")
	if err != nil {
		t.Fatal(err)
	}
	if got != "/srv/media" {
		t.Fatalf("expected root itself, got %q", got)
	}
}

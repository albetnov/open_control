package obs

import (
	"os"
	"os/exec"
	"testing"
)

// TestGeneratedOpcodesUpToDate catches drift between the //obscodegen:decode
// marked structs in opcodes.go and the committed opcodes_gen.go.
func TestGeneratedOpcodesUpToDate(t *testing.T) {
	before, err := os.ReadFile("opcodes_gen.go")
	if err != nil {
		t.Fatalf("reading opcodes_gen.go: %v", err)
	}

	cmd := exec.Command("go", "run", "./internal/opcodegen")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("running opcodegen: %v\n%s", err, out)
	}

	after, err := os.ReadFile("opcodes_gen.go")
	if err != nil {
		t.Fatalf("reading regenerated opcodes_gen.go: %v", err)
	}

	if err := os.WriteFile("opcodes_gen.go", before, 0o644); err != nil {
		t.Fatalf("restoring opcodes_gen.go: %v", err)
	}

	if string(before) != string(after) {
		t.Fatal("opcodes_gen.go is out of date; run `go generate ./...` and commit the result")
	}
}

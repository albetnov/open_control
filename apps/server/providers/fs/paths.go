// Package fs exposes list/read/rename/delete over the configured root
// folder (see providers/settings), with mutating ops staged through a pool
// and only applied on submit.
package fs

import (
	"fmt"
	"path/filepath"
	"strings"
)

// Resolve joins relPath onto root, rejecting anything that would resolve
// outside of it (e.g. "../../etc/passwd"). This is the one place path
// traversal needs to be guarded — every handler routes through it.
func Resolve(root, relPath string) (string, error) {
	cleanRoot := filepath.Clean(root)
	full := filepath.Join(cleanRoot, filepath.Clean(string(filepath.Separator)+relPath))

	if full != cleanRoot && !strings.HasPrefix(full, cleanRoot+string(filepath.Separator)) {
		return "", fmt.Errorf("path escapes root: %q", relPath)
	}
	return full, nil
}

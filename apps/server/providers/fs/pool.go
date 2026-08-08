package fs

import (
	"fmt"
	"os"
	"strconv"
	"sync"
)

type OpType string

const (
	OpRename OpType = "rename"
	OpDelete OpType = "delete"
)

type PoolOp struct {
	ID      string `json:"id"`
	Type    OpType `json:"type"`
	Path    string `json:"path"`
	NewPath string `json:"newPath,omitempty"`
}

// Pool queues mutating FS operations without applying them — CRUD calls only
// stage an intent; Submit is what actually touches disk.
type Pool struct {
	mu     sync.Mutex
	ops    []PoolOp
	nextID int64
}

func (p *Pool) Add(op PoolOp) PoolOp {
	p.mu.Lock()
	defer p.mu.Unlock()

	p.nextID++
	op.ID = strconv.FormatInt(p.nextID, 10)
	p.ops = append(p.ops, op)
	return op
}

func (p *Pool) List() []PoolOp {
	p.mu.Lock()
	defer p.mu.Unlock()
	return append([]PoolOp(nil), p.ops...)
}

func (p *Pool) Remove(id string) bool {
	p.mu.Lock()
	defer p.mu.Unlock()

	for i, op := range p.ops {
		if op.ID == id {
			p.ops = append(p.ops[:i], p.ops[i+1:]...)
			return true
		}
	}
	return false
}

type SubmitResult struct {
	Succeeded []PoolOp `json:"succeeded"`
	Failed    *PoolOp  `json:"failed,omitempty"`
	Error     string   `json:"error,omitempty"`
	Remaining []PoolOp `json:"remaining"`
}

// Submit runs the queued ops against root in order, stopping at the first
// failure. Succeeded ops are dropped from the pool; the failed op and
// everything after it stay queued so they can be retried or removed.
func (p *Pool) Submit(root string) SubmitResult {
	p.mu.Lock()
	defer p.mu.Unlock()

	var result SubmitResult
	failIndex := -1

	for i, op := range p.ops {
		if err := apply(root, op); err != nil {
			failed := op
			result.Failed = &failed
			result.Error = err.Error()
			failIndex = i
			break
		}
		result.Succeeded = append(result.Succeeded, op)
	}

	if failIndex == -1 {
		p.ops = nil
	} else {
		p.ops = p.ops[failIndex:]
		result.Remaining = append([]PoolOp(nil), p.ops[1:]...)
	}

	return result
}

func apply(root string, op PoolOp) error {
	path, err := Resolve(root, op.Path)
	if err != nil {
		return err
	}

	switch op.Type {
	case OpRename:
		newPath, err := Resolve(root, op.NewPath)
		if err != nil {
			return err
		}
		return os.Rename(path, newPath)
	case OpDelete:
		return os.RemoveAll(path)
	default:
		return fmt.Errorf("unknown pool op type: %q", op.Type)
	}
}

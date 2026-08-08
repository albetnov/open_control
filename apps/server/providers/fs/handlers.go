package fs

import (
	"log"
	"os"
	"time"

	fiber "github.com/gofiber/fiber/v3"

	"open_control_server/providers/settings"
)

type entry struct {
	Name    string    `json:"name"`
	IsDir   bool      `json:"isDir"`
	Size    int64     `json:"size"`
	ModTime time.Time `json:"modTime"`
}

type poolRequestBody struct {
	Type    OpType `json:"type"`
	Path    string `json:"path"`
	NewPath string `json:"newPath"`
}

func requireRoot(c fiber.Ctx, store *settings.Store) (string, bool) {
	root := store.FsRoot()
	if root != "" {
		return root, true
	}
	c.Status(fiber.StatusConflict).JSON(fiber.Map{
		"error": "fsRoot is not configured, set it via PUT /settings",
	})
	return "", false
}

// RegisterRoutes wires list/read (live disk) and rename/delete (staged
// through pool, applied only on submit).
func RegisterRoutes(router fiber.Router, store *settings.Store, pool *Pool) {
	router.Get("/fs/list", func(c fiber.Ctx) error {
		root, ok := requireRoot(c, store)
		if !ok {
			return nil
		}

		dir, err := Resolve(root, c.Query("path"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}

		items, err := os.ReadDir(dir)
		if err != nil {
			log.Println("fs: list failed:", err)
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": err.Error()})
		}

		entries := make([]entry, 0, len(items))
		for _, item := range items {
			info, err := item.Info()
			if err != nil {
				continue
			}
			entries = append(entries, entry{
				Name:    item.Name(),
				IsDir:   item.IsDir(),
				Size:    info.Size(),
				ModTime: info.ModTime(),
			})
		}
		return c.JSON(entries)
	})

	router.Get("/fs/file", func(c fiber.Ctx) error {
		root, ok := requireRoot(c, store)
		if !ok {
			return nil
		}

		path, err := Resolve(root, c.Query("path"))
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}

		return c.SendFile(path)
	})

	router.Post("/fs/pool", func(c fiber.Ctx) error {
		root, ok := requireRoot(c, store)
		if !ok {
			return nil
		}

		var body poolRequestBody
		if err := c.Bind().Body(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
		}
		if body.Type != OpRename && body.Type != OpDelete {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "type must be rename or delete"})
		}

		path, err := Resolve(root, body.Path)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		if _, err := os.Stat(path); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "path does not exist"})
		}
		if body.Type == OpRename {
			if _, err := Resolve(root, body.NewPath); err != nil {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
			}
		}

		op := pool.Add(PoolOp{Type: body.Type, Path: body.Path, NewPath: body.NewPath})
		return c.JSON(op)
	})

	router.Get("/fs/pool", func(c fiber.Ctx) error {
		return c.JSON(pool.List())
	})

	router.Delete("/fs/pool/:id", func(c fiber.Ctx) error {
		if !pool.Remove(c.Params("id")) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "no such queued operation"})
		}
		return c.SendStatus(fiber.StatusNoContent)
	})

	router.Post("/fs/submit", func(c fiber.Ctx) error {
		root, ok := requireRoot(c, store)
		if !ok {
			return nil
		}
		return c.JSON(pool.Submit(root))
	})
}

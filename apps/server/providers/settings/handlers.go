package settings

import (
	"log"
	"os"

	fiber "github.com/gofiber/fiber/v3"
)

type updateBody struct {
	ObsPassword *string `json:"obsPassword"`
	FsRoot      *string `json:"fsRoot"`
}

func stateJSON(store *Store) fiber.Map {
	return fiber.Map{
		"obsPasswordSet": store.HasObsPassword(),
		"fsRoot":         store.FsRoot(),
	}
}

// RegisterRoutes wires a single /settings resource: GET reads current state,
// PUT applies a partial update. One endpoint rather than one per field, so
// adding a new setting later doesn't mean adding a new route.
func RegisterRoutes(router fiber.Router, store *Store) {
	router.Get("/settings", func(c fiber.Ctx) error {
		return c.JSON(stateJSON(store))
	})

	router.Put("/settings", func(c fiber.Ctx) error {
		var body updateBody
		if err := c.Bind().Body(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
		}

		if body.FsRoot != nil && *body.FsRoot != "" {
			info, err := os.Stat(*body.FsRoot)
			if err != nil || !info.IsDir() {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "fsRoot must be an existing directory"})
			}
		}

		if err := store.Update(Update{ObsPassword: body.ObsPassword, FsRoot: body.FsRoot}); err != nil {
			log.Println("settings: could not save:", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(stateJSON(store))
	})
}

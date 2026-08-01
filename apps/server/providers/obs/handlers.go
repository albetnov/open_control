package obs

import (
	"log"

	fiber "github.com/gofiber/fiber/v3"
)

func fail(c fiber.Ctx, command string, err error) error {
	log.Println("obs:", command, "failed:", err)
	return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": err.Error()})
}

type setCurrentProgramSceneBody struct {
	SceneName string `json:"sceneName"`
}

// RegisterRoutes wires the OBS MVP command set onto router.
func RegisterRoutes(router fiber.Router, session *ObsSession) {
	router.Get("/obs/scenes", func(c fiber.Ctx) error {
		scenes, err := session.GetSceneList()
		if err != nil {
			return fail(c, "GetSceneList", err)
		}
		return c.JSON(scenes)
	})

	router.Post("/obs/scenes/current", func(c fiber.Ctx) error {
		var body setCurrentProgramSceneBody
		if err := c.Bind().Body(&body); err != nil || body.SceneName == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "sceneName is required"})
		}

		if err := session.SetCurrentProgramScene(body.SceneName); err != nil {
			return fail(c, "SetCurrentProgramScene", err)
		}
		return c.SendStatus(fiber.StatusNoContent)
	})

	router.Get("/obs/stream/status", func(c fiber.Ctx) error {
		status, err := session.GetStreamStatus()
		if err != nil {
			return fail(c, "GetStreamStatus", err)
		}
		return c.JSON(status)
	})

	router.Post("/obs/stream/start", func(c fiber.Ctx) error {
		if err := session.StartStream(); err != nil {
			return fail(c, "StartStream", err)
		}
		return c.SendStatus(fiber.StatusNoContent)
	})

	router.Post("/obs/stream/stop", func(c fiber.Ctx) error {
		if err := session.StopStream(); err != nil {
			return fail(c, "StopStream", err)
		}
		return c.SendStatus(fiber.StatusNoContent)
	})

	router.Get("/obs/record/status", func(c fiber.Ctx) error {
		status, err := session.GetRecordStatus()
		if err != nil {
			return fail(c, "GetRecordStatus", err)
		}
		return c.JSON(status)
	})

	router.Post("/obs/record/start", func(c fiber.Ctx) error {
		if err := session.StartRecord(); err != nil {
			return fail(c, "StartRecord", err)
		}
		return c.SendStatus(fiber.StatusNoContent)
	})

	router.Post("/obs/record/stop", func(c fiber.Ctx) error {
		if err := session.StopRecord(); err != nil {
			return fail(c, "StopRecord", err)
		}
		return c.SendStatus(fiber.StatusNoContent)
	})
}

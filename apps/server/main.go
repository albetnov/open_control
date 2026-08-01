package main

import (
	"fmt"
	"log"

	websocket "github.com/gofiber/contrib/v3/websocket"
	fiber "github.com/gofiber/fiber/v3"

	"open_control_server/providers/mdns"
	"open_control_server/providers/obs"
)

const httpPort = 8888

func setupApp() *fiber.App {
	app := fiber.New()

	session := obs.NewSession("ws://localhost:4455", app)
	obs.RegisterRoutes(app, session)

	mdns.Advertise(app, httpPort)

	app.Get("/", func(c fiber.Ctx) error {
		return c.SendString("SERPER HEALTHYYY WOI")
	})

	app.Get("/ws",
		func(c fiber.Ctx) error {
			if websocket.IsWebSocketUpgrade(c) {
				return c.Next()
			}

			return fiber.ErrUpgradeRequired
		},
		websocket.New(func(c *websocket.Conn) {
			if err := c.WriteMessage(websocket.TextMessage, []byte("test")); err != nil {
				log.Println("websocket write error pula haiya:", err)
			}
		}))

	return app
}

func main() {
	app := setupApp()

	log.Fatal(app.Listen(fmt.Sprintf(":%d", httpPort)))
}

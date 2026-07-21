package obs

import (
	"testing"

	fiber "github.com/gofiber/fiber/v3"
)

func TestIdentify(t *testing.T) {
	// TODO: Use a mock WebSocket server for testing instead of connecting to a real server.
	app := fiber.New()
	session := NewSession("ws://localhost:4455", app)

	if err := session.Identify(); err != nil {
		t.Fatal(err)
	}
}

func TestCloseWithoutConnecting(t *testing.T) {
	app := fiber.New()
	session := NewSession("ws://localhost:4455", app)

	if err := session.Close(); err != nil {
		t.Fatal(err)
	}
}

package mdns

import (
	"context"
	"testing"

	fiber "github.com/gofiber/fiber/v3"
)

func TestAdvertiseDoesNotPanicAndShutsDownCleanly(t *testing.T) {
	app := fiber.New()

	Advertise(app, 18888)

	if err := app.ShutdownWithContext(context.Background()); err != nil {
		t.Fatalf("unexpected shutdown error: %v", err)
	}
}

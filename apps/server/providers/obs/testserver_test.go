package obs

import (
	"context"
	"net"
	"testing"

	websocket "github.com/gofiber/contrib/v3/websocket"
	fiber "github.com/gofiber/fiber/v3"
)

// newFakeObsServer starts an in-process websocket server that speaks just
// enough of the obs-websocket protocol to test session/command logic without
// a live OBS instance: it completes Hello -> Identify -> Identified, then
// replies to Request frames with a scripted RequestResponse looked up by
// requestType in responses (result:false if the type wasn't scripted).
func newFakeObsServer(t *testing.T, responses map[string]map[string]any) string {
	t.Helper()
	return newFakeObsServerImpl(t, responses, false)
}

// newFakeObsServerWithStrayFrame behaves like newFakeObsServer, but writes one
// unsolicited op-5-style frame immediately before the first Request's
// RequestResponse, to test that awaitResponse skips frames that aren't the
// response it's waiting for.
func newFakeObsServerWithStrayFrame(t *testing.T, responses map[string]map[string]any) string {
	t.Helper()
	return newFakeObsServerImpl(t, responses, true)
}

func newFakeObsServerImpl(t *testing.T, responses map[string]map[string]any, injectStrayFrame bool) string {
	t.Helper()

	app := fiber.New()

	app.Get("/", func(c fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	}, websocket.New(func(c *websocket.Conn) {
		if err := c.WriteJSON(&ObsOpcode{Op: 0, D: map[string]any{
			"obsStudioVersion":    "30.0.0",
			"obsWebSocketVersion": "5.0.0",
			"rpcVersion":          1,
		}}); err != nil {
			return
		}

		for {
			raw := &ObsOpcode{}
			if err := c.ReadJSON(raw); err != nil {
				return
			}

			switch raw.Op {
			case 1: // Identify
				if err := c.WriteJSON(&ObsOpcode{Op: 2, D: map[string]any{
					"negotiatedRpcVersion": 1,
				}}); err != nil {
					return
				}
			case 6: // Request
				requestType, _ := raw.D["requestType"].(string)
				requestId, _ := raw.D["requestId"].(string)

				if injectStrayFrame {
					injectStrayFrame = false
					if err := c.WriteJSON(&ObsOpcode{Op: 5, D: map[string]any{
						"eventType": "StrayTestEvent",
						"eventData": map[string]any{},
					}}); err != nil {
						return
					}
				}

				data, ok := responses[requestType]
				status := map[string]any{"result": ok, "code": 100}
				if !ok {
					status["code"] = 600
					status["comment"] = "unscripted requestType: " + requestType
				}

				d := map[string]any{
					"requestType":   requestType,
					"requestId":     requestId,
					"requestStatus": status,
				}
				if data != nil {
					d["responseData"] = data
				}

				if err := c.WriteJSON(&ObsOpcode{Op: 7, D: d}); err != nil {
					return
				}
			}
		}
	}))

	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}

	go func() {
		_ = app.Listener(ln)
	}()
	t.Cleanup(func() {
		_ = app.ShutdownWithContext(context.Background())
	})

	return "ws://" + ln.Addr().String() + "/"
}

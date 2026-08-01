package obs

import (
	"context"
	"net"
	"testing"

	websocket "github.com/gofiber/contrib/v3/websocket"
	fiber "github.com/gofiber/fiber/v3"
)

// newFakeObsServer starts an in-process websocket server that speaks just
// enough of the obs-websocket protocol to test proxy logic without a live OBS
// instance: it completes Hello -> Identify -> Identified, then replies to
// Request frames with a scripted RequestResponse looked up by requestType in
// responses (result:false if the type wasn't scripted).
func newFakeObsServer(t *testing.T, responses map[string]map[string]any) string {
	t.Helper()
	return newFakeObsServerImpl(t, responses, false, nil)
}

// newFakeObsServerWithStrayFrame behaves like newFakeObsServer, but writes one
// unsolicited op-5-style frame immediately before the first Request's
// RequestResponse, to test that a reader tolerates frames it isn't expecting.
func newFakeObsServerWithStrayFrame(t *testing.T, responses map[string]map[string]any) string {
	t.Helper()
	return newFakeObsServerImpl(t, responses, true, nil)
}

// fakeObsAuth configures a fake OBS server to require password auth: its
// Hello carries {salt, challenge}, and it only replies Identified if the
// Identify it receives carries the matching computed authentication string.
type fakeObsAuth struct {
	password  string
	salt      string
	challenge string
}

// newFakeObsServerWithAuth behaves like newFakeObsServer, but requires the
// auth handshake described by auth.
func newFakeObsServerWithAuth(t *testing.T, auth fakeObsAuth, responses map[string]map[string]any) string {
	t.Helper()
	return newFakeObsServerImpl(t, responses, false, &auth)
}

func newFakeObsServerImpl(t *testing.T, responses map[string]map[string]any, injectStrayFrame bool, auth *fakeObsAuth) string {
	t.Helper()

	app := fiber.New()

	app.Get("/", func(c fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	}, websocket.New(func(c *websocket.Conn) {
		helloData := map[string]any{
			"obsStudioVersion":    "30.0.0",
			"obsWebSocketVersion": "5.0.0",
			"rpcVersion":          1,
		}
		if auth != nil {
			helloData["authentication"] = map[string]any{
				"salt":      auth.salt,
				"challenge": auth.challenge,
			}
		}
		if err := c.WriteJSON(&ObsOpcode{Op: 0, D: helloData}); err != nil {
			return
		}

		for {
			raw := &ObsOpcode{}
			if err := c.ReadJSON(raw); err != nil {
				return
			}

			switch raw.Op {
			case 1: // Identify
				if auth != nil {
					want := computeAuthResponse(auth.password, auth.salt, auth.challenge)
					got, _ := raw.D["authentication"].(string)
					if got != want {
						return // real OBS would close with an auth-failure code
					}
				}
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

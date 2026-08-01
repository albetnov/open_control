package main

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/fasthttp/websocket"
	fiber "github.com/gofiber/fiber/v3"
)

func TestHealthRoute(t *testing.T) {
	app := setupApp()

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("unexpected error reading body: %v", err)
	}

	want := "SERPER HEALTHYYY WOI"
	if string(body) != want {
		t.Fatalf("expected body %q, got %q", want, string(body))
	}
}

func TestWsRouteRequiresUpgrade(t *testing.T) {
	app := setupApp()

	req := httptest.NewRequest(http.MethodGet, "/ws", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUpgradeRequired {
		t.Fatalf("expected status %d, got %d", http.StatusUpgradeRequired, resp.StatusCode)
	}
}

// dialWs serves app on a real listener and dials it with a real websocket
// client. A hijacked/upgraded connection keeps its serving goroutine alive
// past the handshake, which races with app.Test()'s in-memory fake-conn
// harness (its response reader and the handler's post-upgrade writes touch
// the same unsynchronized buffer) - a real socket has no such race.
func dialWs(t *testing.T, app *fiber.App, path string) (*websocket.Conn, *http.Response) {
	t.Helper()

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

	url := "ws://" + ln.Addr().String() + path

	var conn *websocket.Conn
	var resp *http.Response
	for i := 0; i < 20; i++ {
		conn, resp, err = websocket.DefaultDialer.Dial(url, nil)
		if err == nil {
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	if err != nil {
		t.Fatalf("failed to dial websocket: %v", err)
	}

	return conn, resp
}

func TestWsRouteAcceptsUpgrade(t *testing.T) {
	app := setupApp()

	conn, resp := dialWs(t, app, "/ws")
	defer conn.Close()

	if resp.StatusCode != http.StatusSwitchingProtocols {
		t.Fatalf("expected status %d, got %d", http.StatusSwitchingProtocols, resp.StatusCode)
	}
}

func TestWsSendsTestMessage(t *testing.T) {
	app := setupApp()

	conn, _ := dialWs(t, app, "/ws")
	defer conn.Close()

	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	msgType, msg, err := conn.ReadMessage()
	if err != nil {
		t.Fatalf("failed to read message: %v", err)
	}

	if msgType != websocket.TextMessage {
		t.Fatalf("expected text message, got type %d", msgType)
	}

	want := "test"
	if string(msg) != want {
		t.Fatalf("expected message %q, got %q", want, string(msg))
	}
}

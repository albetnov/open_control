package obs

import (
	"context"
	"net"
	"testing"
	"time"

	fasthttpws "github.com/fasthttp/websocket"
	fiber "github.com/gofiber/fiber/v3"

	"open_control_server/providers/settings"
)

// newProxyApp registers the proxy route against obsURL and returns the
// ws:// URL of a real listener serving it, cleaned up via t.Cleanup.
func newProxyApp(t *testing.T, obsURL string, store *settings.Store) string {
	t.Helper()

	app := fiber.New()
	RegisterProxyRoute(app, obsURL, store)

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

	return "ws://" + ln.Addr().String() + "/obs/ws"
}

func dialPhone(t *testing.T, url string) *fasthttpws.Conn {
	t.Helper()

	var conn *fasthttpws.Conn
	var err error
	for i := 0; i < 20; i++ {
		conn, _, err = fasthttpws.DefaultDialer.Dial(url, nil)
		if err == nil {
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	if err != nil {
		t.Fatalf("failed to dial proxy: %v", err)
	}
	t.Cleanup(func() { conn.Close() })
	return conn
}

func readOpcode(t *testing.T, conn *fasthttpws.Conn) *ObsOpcode {
	t.Helper()
	conn.SetReadDeadline(time.Now().Add(2 * time.Second))

	raw := &ObsOpcode{}
	if err := conn.ReadJSON(raw); err != nil {
		t.Fatalf("failed to read frame: %v", err)
	}
	return raw
}

func newSettingsStore(t *testing.T) *settings.Store {
	t.Helper()
	store, err := settings.NewStoreAt(t.TempDir() + "/settings.json")
	if err != nil {
		t.Fatal(err)
	}
	return store
}

func TestProxyPassthroughNoAuth(t *testing.T) {
	obsURL := newFakeObsServer(t, map[string]map[string]any{
		"GetSceneList": {"currentProgramSceneName": "Main"},
	})
	proxyURL := newProxyApp(t, obsURL, newSettingsStore(t))
	phone := dialPhone(t, proxyURL)

	hello := readOpcode(t, phone)
	if hello.Op != 0 {
		t.Fatalf("expected Hello (op 0), got op %d", hello.Op)
	}

	if err := phone.WriteJSON(&ObsOpcode{Op: 1, D: map[string]any{"rpcVersion": 1}}); err != nil {
		t.Fatal(err)
	}
	identified := readOpcode(t, phone)
	if identified.Op != 2 {
		t.Fatalf("expected Identified (op 2), got op %d", identified.Op)
	}

	if err := phone.WriteJSON(&ObsOpcode{Op: 6, D: map[string]any{
		"requestType": "GetSceneList",
		"requestId":   "1",
	}}); err != nil {
		t.Fatal(err)
	}
	resp := readOpcode(t, phone)
	if resp.Op != 7 {
		t.Fatalf("expected RequestResponse (op 7), got op %d", resp.Op)
	}
	data, _ := resp.D["responseData"].(map[string]any)
	if data["currentProgramSceneName"] != "Main" {
		t.Fatalf("expected relayed responseData, got %+v", resp.D)
	}
}

func TestProxyInjectsComputedAuthResponse(t *testing.T) {
	const password = "hunter2"
	const salt = "PZVbYpvAnZut2SS6JNJytDm9"
	const challenge = "ztTBnnuqrqaKDzRM3xcVdbYm"

	obsURL := newFakeObsServerWithAuth(t, fakeObsAuth{
		password:  password,
		salt:      salt,
		challenge: challenge,
	}, nil)

	store := newSettingsStore(t)
	if err := store.Update(settings.Update{ObsPassword: strPtr(password)}); err != nil {
		t.Fatal(err)
	}

	proxyURL := newProxyApp(t, obsURL, store)
	phone := dialPhone(t, proxyURL)

	hello := readOpcode(t, phone)
	if hello.Op != 0 {
		t.Fatalf("expected Hello (op 0), got op %d", hello.Op)
	}

	// The phone never knows a password is involved - same Identify it always sends.
	if err := phone.WriteJSON(&ObsOpcode{Op: 1, D: map[string]any{"rpcVersion": 1}}); err != nil {
		t.Fatal(err)
	}

	identified := readOpcode(t, phone)
	if identified.Op != 2 {
		t.Fatalf("expected Identified (op 2) after injected auth, got op %d: %+v", identified.Op, identified.D)
	}
}

func strPtr(s string) *string { return &s }

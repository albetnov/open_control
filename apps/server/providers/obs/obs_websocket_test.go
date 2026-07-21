package obs

import "testing"

func TestConnect(t *testing.T) {
	// TODO: Use a mock WebSocket server for testing instead of connecting to a real server.
	Connect("ws://localhost:4455")
}

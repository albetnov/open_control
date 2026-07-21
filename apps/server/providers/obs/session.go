package obs

import (
	"fmt"
	"net/http"
	"time"

	fiber "github.com/gofiber/fiber/v3"

	ws "open_control_server/websocket"
)

const responseTimeout = 5 * time.Second

type ObsSession struct {
	url       string
	header    http.Header
	transport *transport
	hello     *HelloOp
}

// NewSession constructs a session for the given OBS websocket URL and registers
// its Close against the Fiber app's shutdown hooks. The connection itself is
// not opened until the session is first used (e.g. via Identify).
func NewSession(url string, app *fiber.App) *ObsSession {
	s := &ObsSession{
		url: url,
		header: http.Header{
			"Sec-Websocket-Protocol": []string{"obswebsocket.json"},
		},
	}

	app.Hooks().OnPreShutdown(func() error {
		return s.Close()
	})

	return s
}

func expectOp[T OpCode](op OpCode) (T, error) {
	v, ok := op.(T)
	if !ok {
		var zero T
		return zero, fmt.Errorf("expected %T, got %T", zero, op)
	}

	return v, nil
}

func (s *ObsSession) ensureConnected() error {
	if s.transport != nil {
		return nil
	}

	client, err := ws.OpenConnection(s.url, s.header)
	if err != nil {
		return err
	}
	s.transport = &transport{client: client}

	op, err := s.transport.receive(time.Now().Add(responseTimeout))
	if err != nil {
		return err
	}

	hello, err := expectOp[*HelloOp](op)
	if err != nil {
		return err
	}
	s.hello = hello

	return nil
}

// Identify dials the OBS websocket if not already connected, then completes
// the Hello -> Identify -> Identified handshake.
func (s *ObsSession) Identify() error {
	if err := s.ensureConnected(); err != nil {
		return err
	}

	identify := &IdentifyOp{RPCVersion: s.hello.RPCVersion}
	if err := s.transport.send(&ObsOpcode{
		Op: identify.GetOp(),
		D: map[string]any{
			"rpcVersion": identify.RPCVersion,
		},
	}); err != nil {
		return err
	}

	op, err := s.transport.receive(time.Now().Add(responseTimeout))
	if err != nil {
		return err
	}

	_, err = expectOp[*IdentifiedOp](op)
	return err
}

// Close releases the underlying websocket connection, if one was ever opened.
func (s *ObsSession) Close() error {
	if s.transport == nil {
		return nil
	}

	return s.transport.close()
}

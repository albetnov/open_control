package obs

import (
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	fiber "github.com/gofiber/fiber/v3"

	ws "open_control_server/websocket"
)

const responseTimeout = 5 * time.Second

type ObsSession struct {
	url    string
	header http.Header

	// ponytail: single global mutex serializes every OBS request end-to-end
	// (send + await); correct/simple for one phone client on one connection.
	// Upgrade to a background reader + per-requestId pending map if concurrent
	// in-flight requests or event subscriptions are ever needed.
	mu         sync.Mutex
	transport  *transport
	hello      *HelloOp
	requestSeq int64
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

// ensureConnected must be called with s.mu held.
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
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.identifyLocked()
}

// identifyLocked must be called with s.mu held.
func (s *ObsSession) identifyLocked() error {
	if err := s.ensureConnected(); err != nil {
		return err
	}

	identify := &IdentifyOp{RPCVersion: s.hello.RPCVersion}
	if err := s.transport.send(&ObsOpcode{
		Op: identify.GetOp(),
		D: map[string]any{
			"rpcVersion": identify.RPCVersion,
			// No event feature exists yet; suppress OBS's default "All" event
			// subscription so idle unsolicited Event frames don't pile up.
			"eventSubscriptions": 0,
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

// Request sends an OBS request and waits for its correlated response,
// connecting and identifying first if needed. On success it returns the
// response's data payload (nil if the request has none); on a requestStatus
// failure it returns an error describing the OBS-reported reason.
func (s *ObsSession) Request(requestType string, requestData map[string]any) (map[string]any, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.transport == nil {
		if err := s.identifyLocked(); err != nil {
			return nil, err
		}
	}

	s.requestSeq++
	requestId := strconv.FormatInt(s.requestSeq, 10)

	d := map[string]any{
		"requestType": requestType,
		"requestId":   requestId,
	}
	if requestData != nil {
		d["requestData"] = requestData
	}

	if err := s.transport.send(&ObsOpcode{Op: 6, D: d}); err != nil {
		s.transport = nil
		return nil, err
	}

	resp, err := s.transport.awaitResponse(requestId, time.Now().Add(responseTimeout))
	if err != nil {
		s.transport = nil
		return nil, err
	}

	if !resp.RequestStatus.Result {
		return nil, fmt.Errorf("obs request %s failed (code %d): %s", requestType, resp.RequestStatus.Code, resp.RequestStatus.Comment)
	}

	return resp.ResponseData, nil
}

// Close releases the underlying websocket connection, if one was ever opened.
func (s *ObsSession) Close() error {
	if s.transport == nil {
		return nil
	}

	return s.transport.close()
}

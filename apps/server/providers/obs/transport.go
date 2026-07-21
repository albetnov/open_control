package obs

import (
	"fmt"
	"time"

	ws "open_control_server/websocket"
)

// transport speaks OBS's op/d JSON envelope over a raw websocket connection:
// every outgoing frame is an *ObsOpcode, and every incoming frame is decoded
// through Decode into a concrete OpCode.
type transport struct {
	client *ws.WebsocketClient
}

func (t *transport) send(raw *ObsOpcode) error {
	return t.client.SendMessage(raw)
}

func (t *transport) receive(deadline time.Time) (OpCode, error) {
	res, err := t.client.WaitForResponse(deadline)
	if err != nil {
		return nil, err
	}

	if !res.IsTextMessage() {
		return nil, fmt.Errorf("expected text message, got type: %d", res.MsgType)
	}

	raw := &ObsOpcode{}
	if err := res.ParseMessage(raw); err != nil {
		return nil, err
	}

	return Decode(raw)
}

func (t *transport) close() error {
	return t.client.Close()
}

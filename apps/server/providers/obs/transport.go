package obs

import (
	"fmt"
	"log"
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

// receiveRaw reads the next frame off the wire and unmarshals its envelope,
// without decoding it into a concrete OpCode.
func (t *transport) receiveRaw(deadline time.Time) (*ObsOpcode, error) {
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

	return raw, nil
}

func (t *transport) receive(deadline time.Time) (OpCode, error) {
	raw, err := t.receiveRaw(deadline)
	if err != nil {
		return nil, err
	}

	return Decode(raw)
}

// awaitResponse reads frames until it finds the RequestResponse matching
// requestId, logging and skipping anything else (unsolicited Events, stray
// frames, mismatched requestIds) in the meantime. A read/decode failure at
// the wire level aborts immediately.
func (t *transport) awaitResponse(requestId string, deadline time.Time) (*RequestResponseOp, error) {
	for {
		raw, err := t.receiveRaw(deadline)
		if err != nil {
			return nil, err
		}

		if raw.Op != 7 {
			log.Printf("obs: ignoring unsolicited op %d frame while awaiting response", raw.Op)
			continue
		}

		resp := &RequestResponseOp{}
		if err := resp.Parse(raw); err != nil {
			return nil, err
		}

		if resp.RequestId != requestId {
			log.Printf("obs: ignoring response for requestId %q, awaiting %q", resp.RequestId, requestId)
			continue
		}

		return resp, nil
	}
}

func (t *transport) close() error {
	return t.client.Close()
}

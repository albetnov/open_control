package websocket

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/fasthttp/websocket"
)

type WebsocketClient struct {
	conn *websocket.Conn
}

func OpenConnection(url string, header http.Header) (*WebsocketClient, error) {
	con, _, err := websocket.DefaultDialer.Dial(url, header)
	if err != nil {
		return nil, fmt.Errorf("error connecting to socket %s: %w", url, err)
	}

	return &WebsocketClient{conn: con}, nil
}

func (c *WebsocketClient) WaitForResponse(deadline time.Time) (WebsocketResponse, error) {
	if err := c.conn.SetReadDeadline(deadline); err != nil {
		return WebsocketResponse{}, fmt.Errorf("error setting read deadline: %w", err)
	}

	msgType, msg, err := c.conn.ReadMessage()
	if err != nil {
		return WebsocketResponse{}, fmt.Errorf("error reading message: %w", err)
	}

	return WebsocketResponse{MsgType: msgType, Msg: msg}, nil
}

func (c *WebsocketClient) Close() error {
	return c.conn.Close()
}

type WebsocketResponse struct {
	MsgType int
	Msg     []byte
}

func (r *WebsocketResponse) IsTextMessage() bool {
	return r.MsgType == websocket.TextMessage
}

func (r *WebsocketResponse) IsBinaryMessage() bool {
	return r.MsgType == websocket.BinaryMessage
}

func (r *WebsocketResponse) IsCloseMessage() bool {
	return r.MsgType == websocket.CloseMessage
}

func (r *WebsocketResponse) IsPingMessage() bool {
	return r.MsgType == websocket.PingMessage
}

func (r *WebsocketResponse) IsPongMessage() bool {
	return r.MsgType == websocket.PongMessage
}

func (r *WebsocketResponse) ParseMessage(to any) error {
	err := json.Unmarshal(r.Msg, to)
	if err != nil {
		return fmt.Errorf("GetMessage failed, %w", err)
	}

	return nil
}

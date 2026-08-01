package obs

import (
	"log"
	"net/http"
	"time"

	websocket "github.com/gofiber/contrib/v3/websocket"
	fiber "github.com/gofiber/fiber/v3"

	"open_control_server/providers/settings"
	ws "open_control_server/websocket"
)

// helloTimeout bounds only the initial connect-and-wait-for-Hello step; the
// ongoing relay loops block indefinitely, since a live connection can go
// quiet between requests/events without that meaning anything is wrong.
const helloTimeout = 5 * time.Second

func obsHeader() http.Header {
	return http.Header{"Sec-Websocket-Protocol": []string{"obswebsocket.json"}}
}

// RegisterProxyRoute registers a websocket route that relays obs-websocket
// frames between a phone client and a real OBS instance at obsURL. The phone
// speaks the exact same protocol it would to OBS directly — every frame is
// forwarded untouched except the one case handled here: injecting a computed
// password-auth response into Identify when OBS requires one. Add further
// cases to the switch in relayPhoneToObs/relayObsToPhone as they come up.
func RegisterProxyRoute(router fiber.Router, obsURL string, store *settings.Store) {
	router.Get("/obs/ws",
		func(c fiber.Ctx) error {
			if websocket.IsWebSocketUpgrade(c) {
				return c.Next()
			}
			return fiber.ErrUpgradeRequired
		},
		websocket.New(func(phone *websocket.Conn) {
			proxy(phone, obsURL, store)
		}),
	)
}

func proxy(phone *websocket.Conn, obsURL string, store *settings.Store) {
	client, err := ws.OpenConnection(obsURL, obsHeader())
	if err != nil {
		log.Println("obs proxy: could not connect to OBS:", err)
		return
	}

	helloRaw, salt, challenge, err := readHello(client)
	if err != nil {
		log.Println("obs proxy: did not receive a valid Hello from OBS:", err)
		client.Close()
		return
	}
	if err := phone.WriteJSON(helloRaw); err != nil {
		client.Close()
		return
	}

	done := make(chan struct{})
	go func() {
		defer close(done)
		relayObsToPhone(client, phone)
	}()

	relayPhoneToObs(phone, client, salt, challenge, store)

	client.Close() // unblocks relayObsToPhone's pending read so it can exit
	<-done
}

// readHello waits for OBS's Hello frame and pulls out its auth challenge, if
// any. The frame itself is returned as-is so it can be forwarded unmodified.
func readHello(client *ws.WebsocketClient) (raw *ObsOpcode, salt string, challenge string, err error) {
	resp, err := client.WaitForResponse(time.Now().Add(helloTimeout))
	if err != nil {
		return nil, "", "", err
	}

	raw = &ObsOpcode{}
	if err := resp.ParseMessage(raw); err != nil {
		return nil, "", "", err
	}

	if auth, ok := raw.D["authentication"].(map[string]any); ok {
		salt, _ = auth["salt"].(string)
		challenge, _ = auth["challenge"].(string)
	}

	return raw, salt, challenge, nil
}

func relayObsToPhone(client *ws.WebsocketClient, phone *websocket.Conn) {
	for {
		resp, err := client.WaitForResponse(time.Time{})
		if err != nil {
			return
		}

		raw := &ObsOpcode{}
		if err := resp.ParseMessage(raw); err != nil {
			return
		}

		if err := phone.WriteJSON(raw); err != nil {
			return
		}
	}
}

func relayPhoneToObs(phone *websocket.Conn, client *ws.WebsocketClient, salt, challenge string, store *settings.Store) {
	for {
		raw := &ObsOpcode{}
		if err := phone.ReadJSON(raw); err != nil {
			return
		}

		if raw.Op == 1 && challenge != "" { // Identify, and OBS requires auth
			if password := store.ObsPassword(); password != "" {
				raw.D["authentication"] = computeAuthResponse(password, salt, challenge)
			} else {
				log.Println("obs proxy: OBS requires a password but none is configured")
			}
		}

		if err := client.SendMessage(raw); err != nil {
			return
		}
	}
}

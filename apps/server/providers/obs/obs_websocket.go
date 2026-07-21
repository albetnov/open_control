package obs

import (
	"log"
	"net/http"
	"time"

	ws "open_control_server/websocket"
)

func Connect(url string) {
	header := http.Header{
		"Sec-Websocket-Protocol": []string{"obswebsocket.json"},
	}

	client, err := ws.OpenConnection(url, header)

	if err != nil {
		log.Fatal("error connecting to socket:", url, "header:", header, "error:", err)
		return
	}
	defer client.Close()

	res, err := client.WaitForResponse(time.Now().Add(5 * time.Second))
	if err != nil {
		log.Fatal("Error reading message:", err)
		return
	}

	if !res.IsTextMessage() {
		log.Fatal("Expected text message, got type:", res.MsgType)
	}

	opCode := &ObsOpcode{}
	if err := res.ParseMessage(opCode); err != nil {
		log.Fatal("Erorr parsing message:", err)
		return
	}

	log.Println("opCode:", opCode)

	op, err := GetOpcodeFor(opCode.Op)
	if err != nil {
		log.Fatal(err)
		return
	}

	helloOp, ok := op.(*HelloOp)
	if !ok {
		log.Fatal("Unexpected opcode type:", opCode.Op)
		return
	}

	if err := helloOp.Parse(opCode); err != nil {
		log.Fatal(err)
		return
	}

	log.Println("Hello message received:", helloOp)
}

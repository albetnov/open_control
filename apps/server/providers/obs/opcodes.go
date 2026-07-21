package obs

import "fmt"

//go:generate go run ./internal/opcodegen

type OpCode interface {
	GetOp() int
	Parse(opCode *ObsOpcode) error
}

type ObsOpcode struct {
	Op int            `json:"op"`
	D  map[string]any `json:"d"`
}

//obscodegen:decode
type HelloOp struct {
	ObsStudioVersion    string          `json:"obsStudioVersion"`
	ObsWebsocketVersion string          `json:"obsWebSocketVersion"`
	RPCVersion          int             `json:"rpcVersion"`
	Authentication      *Authentication `json:"authentication,omitempty"`
}

func (h *HelloOp) GetOp() int {
	return 0
}

//obscodegen:decode
type Authentication struct {
	Salt      string `json:"salt"`
	Challenge string `json:"challenge"`
}

type IdentifyOp struct {
	RPCVersion     int    `json:"rpcVersion"`
	Authentication string `json:"authentication,omitempty"`
}

func (i *IdentifyOp) GetOp() int {
	return 1
}

func (i *IdentifyOp) Parse(opCode *ObsOpcode) error {
	return fmt.Errorf("identify op: not an incoming opcode")
}

//obscodegen:decode
type IdentifiedOp struct {
	NegotiatedRpcVersion int `json:"negotiatedRpcVersion"`
}

func (i *IdentifiedOp) GetOp() int {
	return 2
}

func GetOpcodeFor(op int) (OpCode, error) {
	switch op {
	case 0:
		return &HelloOp{}, nil
	case 2:
		return &IdentifiedOp{}, nil
	}

	return nil, fmt.Errorf("unknown opcode: %d", op)
}

func Decode(raw *ObsOpcode) (OpCode, error) {
	op, err := GetOpcodeFor(raw.Op)
	if err != nil {
		return nil, err
	}

	if err := op.Parse(raw); err != nil {
		return nil, err
	}

	return op, nil
}

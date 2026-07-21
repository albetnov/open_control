package obs

import "fmt"

type OpCode interface {
	GetOp() int
	Parse(opCode *ObsOpcode) error
}

type ObsOpcode struct {
	Op int            `json:"op"`
	D  map[string]any `json:"d"`
}

type HelloOp struct {
	ObsStudioVersion    string          `json:"obsStudioVersion"`
	ObsWebsocketVersion string          `json:"obsWebSocketVersion"`
	RPCVersion          int             `json:"rpcVersion"`
	Authentication      *Authentication `json:"authentication,omitempty"`
}

func (h *HelloOp) GetOp() int {
	return 0
}

func (h *HelloOp) Parse(opCode *ObsOpcode) error {
	obsStudioVersion, ok := opCode.D["obsStudioVersion"].(string)
	if !ok {
		return fmt.Errorf("hello op: missing or invalid obsStudioVersion")
	}

	obsWebsocketVersion, ok := opCode.D["obsWebSocketVersion"].(string)
	if !ok {
		return fmt.Errorf("hello op: missing or invalid obsWebSocketVersion")
	}

	rpcVersion, ok := opCode.D["rpcVersion"].(float64)
	if !ok {
		return fmt.Errorf("hello op: missing or invalid rpcVersion")
	}

	h.ObsStudioVersion = obsStudioVersion
	h.ObsWebsocketVersion = obsWebsocketVersion
	h.RPCVersion = int(rpcVersion)

	if auth, ok := opCode.D["authentication"]; ok {
		authMap, ok := auth.(map[string]any)
		if !ok {
			return fmt.Errorf("hello op: invalid authentication payload")
		}

		salt, ok := authMap["salt"].(string)
		if !ok {
			return fmt.Errorf("hello op: missing or invalid authentication salt")
		}

		challenge, ok := authMap["challenge"].(string)
		if !ok {
			return fmt.Errorf("hello op: missing or invalid authentication challenge")
		}

		h.Authentication = &Authentication{
			Salt:      salt,
			Challenge: challenge,
		}
	}

	return nil
}

type Authentication struct {
	Salt      string `json:"salt"`
	Challenge string `json:"challenge"`
}

func GetOpcodeFor(op int) (OpCode, error) {
	switch op {
	case 0:
		return &HelloOp{}, nil
	}

	return nil, fmt.Errorf("unknown opcode: %d", op)
}

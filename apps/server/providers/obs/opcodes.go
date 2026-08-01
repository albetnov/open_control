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

// RequestOp is sent to invoke an OBS request (e.g. GetSceneList). It is
// outgoing-only; OBS never sends this op back to a client.
type RequestOp struct {
	RequestType string         `json:"requestType"`
	RequestId   string         `json:"requestId"`
	RequestData map[string]any `json:"requestData,omitempty"`
}

func (r *RequestOp) GetOp() int {
	return 6
}

func (r *RequestOp) Parse(opCode *ObsOpcode) error {
	return fmt.Errorf("request op: not an incoming opcode")
}

type RequestStatus struct {
	Result  bool   `json:"result"`
	Code    int    `json:"code"`
	Comment string `json:"comment,omitempty"`
}

// RequestResponseOp carries the result of a previously sent RequestOp,
// correlated by RequestId. Hand-decoded rather than routed through the
// obscodegen marker convention: RequestStatus and ResponseData aren't among
// the generator's supported field kinds (bool, generic map), and extending it
// for the benefit of this one struct isn't worth it.
type RequestResponseOp struct {
	RequestType   string
	RequestId     string
	RequestStatus RequestStatus
	ResponseData  map[string]any
}

func (r *RequestResponseOp) GetOp() int {
	return 7
}

func (r *RequestResponseOp) Parse(opCode *ObsOpcode) error {
	requestType, ok := opCode.D["requestType"].(string)
	if !ok {
		return fmt.Errorf("request response op: missing or invalid requestType")
	}
	r.RequestType = requestType

	requestId, ok := opCode.D["requestId"].(string)
	if !ok {
		return fmt.Errorf("request response op: missing or invalid requestId")
	}
	r.RequestId = requestId

	statusRaw, ok := opCode.D["requestStatus"].(map[string]any)
	if !ok {
		return fmt.Errorf("request response op: missing or invalid requestStatus")
	}

	result, ok := statusRaw["result"].(bool)
	if !ok {
		return fmt.Errorf("request response op: missing or invalid requestStatus.result")
	}
	code, ok := statusRaw["code"].(float64)
	if !ok {
		return fmt.Errorf("request response op: missing or invalid requestStatus.code")
	}
	comment, _ := statusRaw["comment"].(string)

	r.RequestStatus = RequestStatus{Result: result, Code: int(code), Comment: comment}

	if raw, ok := opCode.D["responseData"]; ok {
		data, ok := raw.(map[string]any)
		if !ok {
			return fmt.Errorf("request response op: invalid responseData")
		}
		r.ResponseData = data
	}

	return nil
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

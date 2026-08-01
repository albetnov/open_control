package obs

// ObsOpcode is the generic obs-websocket op/d envelope. The proxy only ever
// needs Op plus specific keys out of D (e.g. requestType, eventType,
// authentication) — not typed per-opcode structs.
type ObsOpcode struct {
	Op int            `json:"op"`
	D  map[string]any `json:"d"`
}

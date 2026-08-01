package obs

import "encoding/json"

// decodeResponseData round-trips a request's generic responseData map into a
// typed struct via stdlib JSON. The 8 commands' response shapes vary too much
// (slices, bools, nested objects) for the opcodes.go codegen's 3 field kinds,
// and this is a different concern (command DTOs, not protocol envelopes).
func decodeResponseData(data map[string]any, out any) error {
	raw, err := json.Marshal(data)
	if err != nil {
		return err
	}

	return json.Unmarshal(raw, out)
}

type Scene struct {
	SceneName  string `json:"sceneName"`
	SceneIndex int    `json:"sceneIndex"`
}

type GetSceneListResponse struct {
	Scenes                  []Scene `json:"scenes"`
	CurrentProgramSceneName string  `json:"currentProgramSceneName"`
	CurrentPreviewSceneName string  `json:"currentPreviewSceneName"`
}

type StreamStatus struct {
	OutputActive       bool   `json:"outputActive"`
	OutputReconnecting bool   `json:"outputReconnecting"`
	OutputTimecode     string `json:"outputTimecode"`
	OutputDuration     int    `json:"outputDuration"`
	OutputBytes        int    `json:"outputBytes"`
}

type RecordStatus struct {
	OutputActive   bool   `json:"outputActive"`
	OutputPaused   bool   `json:"outputPaused"`
	OutputTimecode string `json:"outputTimecode"`
	OutputDuration int    `json:"outputDuration"`
	OutputBytes    int    `json:"outputBytes"`
}

func (s *ObsSession) GetSceneList() (GetSceneListResponse, error) {
	var out GetSceneListResponse

	data, err := s.Request("GetSceneList", nil)
	if err != nil {
		return out, err
	}

	err = decodeResponseData(data, &out)
	return out, err
}

func (s *ObsSession) SetCurrentProgramScene(sceneName string) error {
	_, err := s.Request("SetCurrentProgramScene", map[string]any{"sceneName": sceneName})
	return err
}

func (s *ObsSession) GetStreamStatus() (StreamStatus, error) {
	var out StreamStatus

	data, err := s.Request("GetStreamStatus", nil)
	if err != nil {
		return out, err
	}

	err = decodeResponseData(data, &out)
	return out, err
}

func (s *ObsSession) GetRecordStatus() (RecordStatus, error) {
	var out RecordStatus

	data, err := s.Request("GetRecordStatus", nil)
	if err != nil {
		return out, err
	}

	err = decodeResponseData(data, &out)
	return out, err
}

func (s *ObsSession) StartStream() error {
	_, err := s.Request("StartStream", nil)
	return err
}

func (s *ObsSession) StopStream() error {
	_, err := s.Request("StopStream", nil)
	return err
}

func (s *ObsSession) StartRecord() error {
	_, err := s.Request("StartRecord", nil)
	return err
}

func (s *ObsSession) StopRecord() error {
	_, err := s.Request("StopRecord", nil)
	return err
}

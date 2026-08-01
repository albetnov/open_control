package obs

import (
	"strings"
	"sync"
	"testing"

	fiber "github.com/gofiber/fiber/v3"
)

func newTestSession(t *testing.T, responses map[string]map[string]any) *ObsSession {
	t.Helper()

	url := newFakeObsServer(t, responses)
	return NewSession(url, fiber.New())
}

func TestGetSceneList(t *testing.T) {
	session := newTestSession(t, map[string]map[string]any{
		"GetSceneList": {
			"scenes":                  []any{map[string]any{"sceneName": "Main", "sceneIndex": 0}},
			"currentProgramSceneName": "Main",
			"currentPreviewSceneName": "Main",
		},
	})

	scenes, err := session.GetSceneList()
	if err != nil {
		t.Fatal(err)
	}

	if len(scenes.Scenes) != 1 || scenes.Scenes[0].SceneName != "Main" {
		t.Fatalf("unexpected scenes: %+v", scenes)
	}
	if scenes.CurrentProgramSceneName != "Main" {
		t.Fatalf("expected current program scene Main, got %q", scenes.CurrentProgramSceneName)
	}
}

func TestSetCurrentProgramScene(t *testing.T) {
	session := newTestSession(t, map[string]map[string]any{
		"SetCurrentProgramScene": nil,
	})

	if err := session.SetCurrentProgramScene("Intermission"); err != nil {
		t.Fatal(err)
	}
}

func TestStartStream(t *testing.T) {
	session := newTestSession(t, map[string]map[string]any{
		"StartStream": nil,
	})

	if err := session.StartStream(); err != nil {
		t.Fatal(err)
	}
}

func TestRequestErrorPropagation(t *testing.T) {
	session := newTestSession(t, map[string]map[string]any{})

	err := session.StartStream()
	if err == nil {
		t.Fatal("expected error for unscripted requestType, got nil")
	}
	if !strings.Contains(err.Error(), "code 600") {
		t.Fatalf("expected error to mention code 600, got: %v", err)
	}
}

func TestConcurrentRequests(t *testing.T) {
	session := newTestSession(t, map[string]map[string]any{
		"GetStreamStatus": {"outputActive": true, "outputReconnecting": false, "outputTimecode": "00:00:01", "outputDuration": 1000, "outputBytes": 100},
		"GetRecordStatus": {"outputActive": false, "outputPaused": false, "outputTimecode": "00:00:00", "outputDuration": 0, "outputBytes": 0},
	})

	var wg sync.WaitGroup
	var streamErr, recordErr error
	var streamStatus StreamStatus
	var recordStatus RecordStatus

	wg.Add(2)
	go func() {
		defer wg.Done()
		streamStatus, streamErr = session.GetStreamStatus()
	}()
	go func() {
		defer wg.Done()
		recordStatus, recordErr = session.GetRecordStatus()
	}()
	wg.Wait()

	if streamErr != nil {
		t.Fatal(streamErr)
	}
	if recordErr != nil {
		t.Fatal(recordErr)
	}

	if !streamStatus.OutputActive {
		t.Fatalf("expected stream status outputActive=true, got %+v", streamStatus)
	}
	if recordStatus.OutputActive {
		t.Fatalf("expected record status outputActive=false, got %+v", recordStatus)
	}
}

func TestAwaitResponseIgnoresUnsolicitedFrame(t *testing.T) {
	url := newFakeObsServerWithStrayFrame(t, map[string]map[string]any{
		"GetStreamStatus": {"outputActive": true},
	})
	session := NewSession(url, fiber.New())

	status, err := session.GetStreamStatus()
	if err != nil {
		t.Fatal(err)
	}
	if !status.OutputActive {
		t.Fatalf("expected outputActive=true, got %+v", status)
	}
}

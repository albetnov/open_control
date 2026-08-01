package obs

import "testing"

func TestComputeAuthResponse(t *testing.T) {
	got := computeAuthResponse(
		"supersecretpassword",
		"PZVbYpvAnZut2SS6JNJytDm9",
		"ztTBnnuqrqaKDzRM3xcVdbYm",
	)
	want := "zZgWipvwSGrw748kHN4gNpBC1IaeiiWX3Hjkrm849Sc="
	if got != want {
		t.Fatalf("expected %q, got %q", want, got)
	}
}

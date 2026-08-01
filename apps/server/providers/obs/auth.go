package obs

import (
	"crypto/sha256"
	"encoding/base64"
)

// computeAuthResponse implements obs-websocket's password-auth algorithm
// (unchanged between v4 and v5):
//  1. secret = base64(sha256(password + salt))
//  2. authentication = base64(sha256(secret + challenge))
func computeAuthResponse(password, salt, challenge string) string {
	secretHash := sha256.Sum256([]byte(password + salt))
	secret := base64.StdEncoding.EncodeToString(secretHash[:])

	authHash := sha256.Sum256([]byte(secret + challenge))
	return base64.StdEncoding.EncodeToString(authHash[:])
}

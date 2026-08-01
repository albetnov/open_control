// Package mdns advertises this server on the LAN so the phone app can find it
// without the user typing an IP address.
package mdns

import (
	"log"
	"os"

	fiber "github.com/gofiber/fiber/v3"
	hashimdns "github.com/hashicorp/mdns"
)

// ServiceType is the mDNS/DNS-SD service type this server advertises under.
// Must match the discovery side's service type exactly.
const ServiceType = "_open-control._tcp"

// Advertise registers this server via mDNS and wires its shutdown into app's
// shutdown hooks. mDNS is a discovery convenience, not a requirement — manual
// host/port entry always remains available — so any failure here is logged
// and swallowed rather than propagated.
func Advertise(app *fiber.App, port int) {
	host, err := os.Hostname()
	if err != nil {
		log.Println("mdns: could not determine hostname, skipping advertisement:", err)
		return
	}

	service, err := hashimdns.NewMDNSService(host, ServiceType, "", "", port, nil, nil)
	if err != nil {
		log.Println("mdns: could not build service record, skipping advertisement:", err)
		return
	}

	server, err := hashimdns.NewServer(&hashimdns.Config{Zone: service})
	if err != nil {
		log.Println("mdns: could not start advertisement:", err)
		return
	}

	app.Hooks().OnPreShutdown(func() error {
		return server.Shutdown()
	})
}

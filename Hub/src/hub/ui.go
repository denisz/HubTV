package hub

import (
	"fmt"
	"time"
	"github.com/dustin/go-humanize"
)

func NewRender(server *Server) {
	stream := server.Stream

	go func () {
		for {
			t := stream.Torrent

			if t == nil || t.Info() == nil {
				time.Sleep(time.Second * 1)
				continue
			}

			info := t.Info()
			downloadSpeed := humanize.Bytes(stream.Speed()) + "/s"
			percentage := stream.Percentage()

			if !stream.IsComplete() {
				fmt.Printf("Progress: %s  %.2f%%\n", info.Name, percentage)
				fmt.Printf("Speed: %s\n", downloadSpeed)
			}

			time.Sleep(time.Second * 5)
		}
	}()
}

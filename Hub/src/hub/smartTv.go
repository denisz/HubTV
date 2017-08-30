package hub

import (
	"net/http"
)

type Tv struct {
	Client *http.Client
	Router *http.ServeMux
}

func NewSmartTvProxy () *Tv {
	server := Tv{}
	router := http.NewServeMux()

	server.Router = router

	router.HandleFunc("/tv", func (w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	})

	router.HandleFunc("/", func (w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	})

	return &server
}

func (p *Tv) Close () {

}


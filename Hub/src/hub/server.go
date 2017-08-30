package hub

import (
	"log"
	"net/http"
	"encoding/json"
	"osdb"
	"yts"
	"hubutils"
	"fmt"
	"os"
)

const (
	_ = iota
	exitErrorInClient
)

type Config struct {}

type Server struct {
	Config *Config
	Stream *Stream
	Router *http.ServeMux
}

func NewServerConfig() *Config {
	cfg := Config{}
	return &cfg
}

func NewServer (cfg *Config) *Server {
	s := Server{}

	cfgStream 	:= NewStreamConfig()
	stream, err 	:= NewStream(cfgStream)

	if err != nil {
		log.Fatalf(err.Error())
		os.Exit(exitErrorInClient)
	}

	router := http.NewServeMux()

	s.Config = cfg
	s.Stream = stream
	s.Router = router

	router.HandleFunc("/", 	  	http.HandlerFunc(s.Index))

	router.HandleFunc("/file",  	http.HandlerFunc(s.GetFile))

	router.HandleFunc("/start", 	http.HandlerFunc(s.Start))

	router.HandleFunc("/stream", 	http.HandlerFunc(s.Streaming))

	router.HandleFunc("/clean", 	http.HandlerFunc(s.Clean))

	router.HandleFunc("/repeat", 	http.HandlerFunc(s.Repeat))

	router.HandleFunc("/stop", 	http.HandlerFunc(s.Stop))

	router.HandleFunc("/search", 	http.HandlerFunc(s.Search))

	router.HandleFunc("/status", 	http.HandlerFunc(s.Status))

	router.HandleFunc("/subtitles", 	http.HandlerFunc(s.Subtitles))

	router.HandleFunc("/ping", func (w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte("pong"))
	})

	return &s
}

func (p *Server) Close () {
	defer p.Stream.Close()
}


func (p *Server) GetFile (w http.ResponseWriter, r *http.Request) {
	p.Stream.GetFile(w, r)
}

func (p *Server) Index (w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
	w.Write([]byte(IndexHtml))
}

func (p *Server) Search (w http.ResponseWriter, r *http.Request) {
	keywords := r.FormValue("keywords")

	if len(keywords) == 0 {
		ResponseWriterError(w, "Passing parameter keywords")
		return
	}

	page := r.FormValue("page")

	//_category := r.FormValue("category")

	query := hubutils.NewSearchQuery(keywords, page)
	result, err := yts.Search(query)

	if err != nil {
		ResponseWriterError(w, "Inner server error")
		return
	}

	bytes, err := json.Marshal(result)

	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
	} else {
		ResponseSuccess(w, bytes)
	}
}

func (p *Server) Subtitles(w http.ResponseWriter, r *http.Request) {
	info, err := p.Stream.Info()

	if err != nil {
		ResponseWriterError(w, "Not found")
		return
	}

	subtitles, err := osdb.Search(&osdb.SearchQuery{
		ImdbId: info.Movie.ImdbID,
		Lang: osdb.LANG_ENG,
	})

	if err != nil {
		ResponseWriterError(w, "Not found subtitles")
	} else {
		w.Header().Set("Content-type", "application/zip")
		ResponseSuccess(w, subtitles)
	}
}

func (p *Server) Clean (w http.ResponseWriter, r *http.Request) {
	p.Stream.Stop()
	p.Stream.Clear()
	w.WriteHeader(200)
	w.Write([]byte("OK"))
}

func(p *Server) Start (w http.ResponseWriter, r *http.Request) {
	id 	:= r.FormValue("id")
	quality := r.FormValue("quality")

	if len(quality) == 0 {
		ResponseWriterError(w, "Passing parameter quality")
		return
	}

	movie, err := yts.Find(id)
	if err != nil {
		ResponseWriterError(w, "Not found movie")
		return
	}

	var link string = ""

	for _, item := range movie.Torrents {
		if item.Quality == quality {
			link = item.Url
		}
	}

	if len(link) == 0 {
		ResponseWriterError(w, "The movie has not magnet link")
		return
	}

	err = p.Stream.StartWithInfo(&StreamInfo{
		Link  : link,
		Movie : movie,
	})

	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
	} else {
		bytes, err := json.Marshal(movie)

		if err != nil {
			ResponseWriterError(w, fmt.Sprintf("%+v", err))
		} else {
			ResponseSuccess(w, bytes)
		}
	}
}

func (p *Server) Streaming (w http.ResponseWriter, r *http.Request) {
	link := r.FormValue("link")

	if len(link) == 0 {
		ResponseWriterError(w, "Passing parameter link")
		return
	}

	movie := hubutils.NewMovie()

	err := p.Stream.StartWithInfo(&StreamInfo{
		Link  : link,
		Movie : movie,
	})

	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
	} else {
		bytes, err := json.Marshal(movie)

		if err != nil {
			ResponseWriterError(w, fmt.Sprintf("%+v", err))
		} else {
			ResponseSuccess(w, bytes)
		}
	}
}

func (p *Server) Repeat (w http.ResponseWriter, r *http.Request) {
	info, err := p.Stream.Info()

	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
		return
	}

	err = p.Stream.StartWithInfo(info)

	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
	} else {
		ResponseSuccess(w, []byte("OK"));
	}
}

func (p *Server) Status (w http.ResponseWriter, r *http.Request) {
	info, err := p.Stream.Info()

	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
		return
	}

	bytes, err := json.Marshal(info)
	if err != nil {
		ResponseWriterError(w, fmt.Sprintf("%+v", err))
		return
	}

	ResponseSuccess(w, bytes)
}

func(p *Server) Stop (w http.ResponseWriter, r *http.Request) {
	p.Stream.Stop()
	w.WriteHeader(200)
	w.Write([]byte("OK"))
}
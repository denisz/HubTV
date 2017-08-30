package hubutils

type CollectionMovies struct {
	MovieTotal int32
	PageNumber int32
	Movies []*MMovie
}

type MMovie struct {
	ID float64
	Title string
	Year float64
	Poster string
	Synopsis string
	ImdbID string
	Provider string
	Torrents []*MTorrent
	Episodes []*MEpisode
	Rating float64
}

type MTorrent struct {
	Quality string
	Size 	string
	Seeds 	float64
	Peers 	float64
	Url  	string
}

type MEpisode struct {
	season int
	episode int
	title string
	overview string

}


func NewMovie () *MMovie {
	movie := &MMovie{}
	return movie

}
package hubutils

type  ItemType int

type SearchQueryMovies struct {
	Keywords    	string
	Year     	string
	Category 	ItemType
	Page 	 	string
}


func NewSearchQuery(keywords string, page string) *SearchQueryMovies{
	query := SearchQueryMovies{
		Keywords 	: keywords,
		Page 		: page,
		Category 	: Movie,
	}

	return &query
}

type SearchQueryMagnet struct {
	Quality string
	ImdbId string
}

const (
	// Unknown is a null item type
	Unknown ItemType = iota
	// Any is used for searching for any item
	Any
	// Movie is the type of a item which is a movie
	Movie
	// Series is the type of a item which is a series
	Series
	// Episode is the type of a item which is an episode
	Episode
	// Quiality 720p
	Quiality720p = "720p"
	// Quiality 1080p
	Quiality1080p = "1080p"

)
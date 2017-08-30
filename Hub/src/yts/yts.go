package yts

import (
	"net/http"
	"fmt"
	"io/ioutil"
	"net/url"
	"strings"
	"encoding/json"
	"hubutils"
	"strconv"
)

type ItemTorrent struct {
	Hash string
	Quality string
	Size string
	Seeds float64
	Peers float64
	Url string
}

type ItemQuery struct {
	Title    string
	Year     float64
	ImdbId   string `json:"imdb_code"`
	URL      string
	Rating   float64
	ID       float64
	Synopsis string `json:"description_full"`
	Cover 	 string `json:"large_cover_image"`
	Language string `json:"language"`
	Torrents []ItemTorrent
}

type ResultQuery struct {
	Data struct{
		MovieTotal int32 `json:"movie_count"`
		PageNumber int32 `json:"page_number"`
		Movies []ItemQuery
		Movie  ItemQuery
	}
}

const (
	High       = "1080p"
	Medium     = "720p"
	SEARCH_URL = "https://yts.ag/api/v2/list_movies.json"
	FIND_URL   = "https://yts.ag/api/v2/movie_details.json"
)

var recommendTracks = []string {
	"udp://open.demonii.com:1337/announce",
	"udp://tracker.openbittorrent.com:80",
	"udp://tracker.coppersurfer.tk:6969",
	"udp://glotorrents.pw:6969/announce",
	"udp://tracker.opentrackr.org:1337/announce",
	"udp://torrent.gresille.org:80/announce",
	"udp://p4p.arenabg.com:1337",
	"udp://tracker.leechers-paradise.org:6969",
}

func Find(id string) (*hubutils.MMovie, error) {
	parameters := url.Values{}
	parameters.Set("movie_id", id)

	url := fmt.Sprintf("%s?%s", FIND_URL, parameters.Encode())

	payload := strings.NewReader("{}")

	req, _ := http.NewRequest("GET", url, payload)

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()

	body, _ := ioutil.ReadAll(res.Body)

	result := ResultQuery{}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	return Transform(&result.Data.Movie), nil
}

func Search(query *hubutils.SearchQueryMovies) (*hubutils.CollectionMovies, error) {
	parameters := url.Values{}

	if query.Keywords != "" {
		parameters.Set("query_term", query.Keywords)
	}

	if query.Page != "" {
		parameters.Set("page", query.Page)
	}

	parameters.Set("limit", strconv.Itoa(50))
	parameters.Set("quality", fmt.Sprintf("%s, %s", High, Medium))

	url := fmt.Sprintf("%s?%s", SEARCH_URL, parameters.Encode())

	payload := strings.NewReader("{}")

	req, _ := http.NewRequest("GET", url, payload)

	res, _ := http.DefaultClient.Do(req)

	defer res.Body.Close()

	body, _ := ioutil.ReadAll(res.Body)

	result := ResultQuery{}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	return Serialize(&result), nil
}

func generateMagnetLink(hash string, title string) string {
	parameters := url.Values{}

	parameters.Set("dn", title)

	for _, tr := range recommendTracks {
		parameters.Add("tr", tr)
	}

	return fmt.Sprintf("magnet:?xt=%s&%s", fmt.Sprintf("urn:btih:%s", hash), parameters.Encode())
}

func Serialize (result *ResultQuery) *hubutils.CollectionMovies {
	collection := hubutils.CollectionMovies{}
	collection.MovieTotal = result.Data.MovieTotal
	collection.PageNumber = result.Data.PageNumber

	movies := result.Data.Movies

	for _, item := range movies {
		collection.Movies = append(collection.Movies, Transform(&item))
	}

	return &collection
}

func Transform (item *ItemQuery) *hubutils.MMovie {
	torrents := []*hubutils.MTorrent{}

	for _, t := range item.Torrents {
		torrent := hubutils.MTorrent{
			Url 	: generateMagnetLink(t.Hash, item.Title),
			Quality : t.Quality,
			Size 	: t.Size,
			Peers 	: t.Peers,
			Seeds 	: t.Seeds,
		}
		torrents = append(torrents, &torrent)
	}

	movie := hubutils.MMovie{
		Title 	: item.Title,
		Poster 	: item.Cover,
		Year 	: item.Year,
		ID 	: item.ID,
		Rating  : item.Rating,
		ImdbID 	: item.ImdbId,
		Provider: "yts",
		Synopsis: item.Synopsis,
		Torrents: torrents,
	}

	return &movie
}
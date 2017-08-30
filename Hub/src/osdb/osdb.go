package osdb

import (
	api "github.com/oz/osdb"
	"strings"
	"io/ioutil"
	"net/http"
	"errors"
	"log"
	"fmt"
)

const (
	LANG_ENG = "eng"
	LANG_RUS = "rus"
)

type SearchQuery struct {
	Lang string
	ImdbId string
}

type Subtitle struct {
	Client *api.Client
	Item *api.Subtitle
	ImdbId string
}

func Search (query *SearchQuery) ([]byte, error) {

	imdbIdPure := strings.TrimPrefix(query.ImdbId, "tt")

	client, err := api.NewClient()
	if err != nil {
		return nil, err
	}

	err = client.LogIn("", "", "")
	if err != nil {
		return nil, err
	}

	subtitles, err := client.IMDBSearchByID([]string{imdbIdPure}, []string{query.Lang})
	if err != nil {
		return nil, err
	}

	best := subtitles.Best()

	if best != nil {
		//return downloadFile(best.ZipDownloadLink)
		return downloadFile(best.SubDownloadLink)
		//path := path.Join(os.TempDir(), "com.apple.mediahub.subtitles")
		//if _, err := os.Stat(path); os.IsNotExist(err) {
		//	os.Mkdir(path, 0777)
		//}
		//
		//file, err := ioutil.TempFile(path, "subtitles")
		//defer os.Remove(file.Name())

		//err = client.DownloadTo(best, file.Name())
		//if err != nil {
		//	return nil, err
		//}
		//
		//return ioutil.ReadFile(file.Name())
	}

	return nil, errors.New("Not found")
}

func downloadFile(URL string) ([]byte, error) {
	fmt.Printf("Load subtitles as %s", URL)

	response, err := http.Get(URL)
	if err != nil {
		return nil, err
	}

	defer func() {
		if _err := response.Body.Close(); _err != nil {
			log.Printf("Error closing torrent file: %s", _err)
		}
	}()

	return ioutil.ReadAll(response.Body)
}
package hub

import (
	"compress/gzip"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/anacrolix/torrent"
	"github.com/anacrolix/torrent/iplist"
	"github.com/anacrolix/torrent/storage"
	"path"
	"path/filepath"
	"encoding/json"
	"hubutils"
	"errors"
)

const torrentBlockListURL 	= "http://john.bitsurge.net/public/biglist.p2p.gz"
const pathDownload 		= "com.apple.mediahub"
const filenameinfo 		= "info.json"

var isHTTP = regexp.MustCompile(`^https?:\/\/`)

type TorrentInfo struct {
	Percentage float64
	Speed uint64
	IsComplete bool
	FileSize int64
	ReadyForPlayback bool
	FileName string
}

type StreamInfo struct {
	Movie 	*hubutils.MMovie
	Link 	string
	Torrent TorrentInfo
}

// StreamError formats errors coming from the client.
type StreamError struct {
	Type   string
	Origin error
}

func (clientError StreamError) Error() string {
	return fmt.Sprintf("Error %s: %s\n", clientError.Type, clientError.Origin)
}

type Stream struct {
	Client   *torrent.Client
	Torrent  *torrent.Torrent
	Progress int64
	Uploaded int64
	Config   StreamConfig
}

// StreamConfig specifies the behaviour of a client.
type StreamConfig struct {
	TorrentPath 	string
	TorrentPort    int
	Seed           bool
	TCP            bool
	MaxConnections int
}

// NewStreamConfig creates a new default configuration.
func NewStreamConfig() StreamConfig {
	return StreamConfig{
		TorrentPath:    path.Join(os.TempDir(), pathDownload),
		TorrentPort:    50007,
		Seed:           false,
		TCP:            true,
		MaxConnections: 200,
	}
}

// NewStream creates a new torrent client based on a magnet or a torrent file.
// If the torrent file is on http, we try downloading it.
func NewStream(cfg StreamConfig) (*Stream, error) {
	var c *torrent.Client
	var err error
	var client = &Stream{}
	client.Config = cfg


	path := cfg.TorrentPath
	if _, err := os.Stat(path); os.IsNotExist(err) {
		os.Mkdir(path, 0777)
	}

	// Create client.
	c, err = torrent.NewClient(&torrent.Config{
		DataDir:    path,
		NoUpload:   !cfg.Seed,
		Seed:       cfg.Seed,
		DisableTCP: !cfg.TCP,
		DefaultStorage: storage.NewBoltDB("./"),
		ListenAddr: fmt.Sprintf(":%d", cfg.TorrentPort),
	})

	if err != nil {
		return client, StreamError{Type: "creating torrent client", Origin: err}
	}

	client.Client = c

	go client.SetIPBlockList()

	return client, nil
}

// Download and add the blocklist.
func (c *Stream) SetIPBlockList() {
	var err error
	path := os.TempDir() + "/go-peerflix-blocklist.gz"

	if _, err = os.Stat(path); os.IsNotExist(err) {
		err = downloadBlockList(path)
	}

	if err != nil {
		log.Printf("Error downloading blocklist: %s", err)
		return
	}

	// Load blocklist.
	reader, err := os.Open(path)
	if err != nil {
		log.Printf("Error opening blocklist: %s", err)
		return
	}

	// Extract file.
	gzipReader, err := gzip.NewReader(reader)
	if err != nil {
		log.Printf("Error extracting blocklist: %s", err)
		return
	}

	// Read as iplist.
	list, err := iplist.NewFromReader(gzipReader)
	if err != nil {
		log.Printf("Error reading blocklist: %s", err)
		return
	}

	c.Client.SetIPBlockList(list)
}

func downloadBlockList(path string) (err error) {
	fileName, err := downloadFile(torrentBlockListURL)
	if err != nil {
		log.Printf("Error downloading blocklist: %s\n", err)
		return
	}

	return os.Rename(fileName, path)
}

// Close cleans up the connections.
func (c *Stream) Close() {
	c.Stop()
	c.Client.Close()
}

func (c *Stream) Clear() error {
	_path := path.Join(os.TempDir(), pathDownload)

	d, err := os.Open(_path)
	if err != nil {
		return err
	}

	defer d.Close()

	names, err := d.Readdirnames(-1)
	if err != nil {
		return err
	}

	for _, name := range names {
		err = os.RemoveAll(filepath.Join(_path, name))
		if err != nil {
			return err
		}
	}

	return nil
}

func (c *Stream) getLargestFile() *torrent.File {
	var target torrent.File
	var maxSize int64
	t := c.Torrent

	if t == nil {
		return nil
	}

	for _, file := range t.Files() {
		if maxSize < file.Length() {
			maxSize = file.Length()
			target = file
		}
	}

	return &target
}

// ReadyForPlayback checks if the torrent is ready for playback or not.
// We wait until 5% of the torrent to start playing.
func (c *Stream) ReadyForPlayback() bool {
	return c.Percentage() > 5
}

// GetFile is an http handler to serve the biggest file managed by the client.
func (c *Stream) GetFile(w http.ResponseWriter, r *http.Request) {
	target := c.getLargestFile()
	if target == nil {
		w.WriteHeader(500)
		w.Write([]byte("Error"))
		return
	}

	entry, err := NewFileReader(target)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer func() {
		if err := entry.Close(); err != nil {
			log.Printf("Error closing file reader: %s\n", err)
		}
	}()

	w.Header().Set("Content-Disposition", "attachment; filename=\""+c.Torrent.Info().Name+"\"")
	http.ServeContent(w, r, target.DisplayPath(), time.Now(), entry)
}

func (c *Stream) Percentage() float64 {
	currentProgress := c.BytesCompleted()
	fileSize := c.FileSize()

	return float64(currentProgress) / float64(fileSize) * 100
}

func (c *Stream) FileSize() int64 {
	t := c.Torrent
	if t == nil {
		return 1
	}

	info := c.Torrent.Info()
	if info == nil {
		return 1
	}

	return info.TotalLength()
}

func (c *Stream) FileName () string {
	t := c.Torrent
	if t == nil {
		return ""
	}

	info := c.Torrent.Info()
	if info == nil {
		return ""
	}

	target := c.getLargestFile()

	if target != nil {
		return target.Path()
	}

	return ""
}

func (c *Stream) BytesCompleted() int64 {
	t := c.Torrent
	if t == nil {
		return 0
	}

	return t.BytesCompleted()
}

func (c *Stream) Speed() uint64 {
	currentProgress := c.BytesCompleted()
	speed := uint64(currentProgress-c.Progress)
	c.Progress = currentProgress

	return speed
}

func (c *Stream) IsComplete() bool {
	return c.BytesCompleted() >= c.FileSize()
}

func downloadFile(URL string) (fileName string, err error) {
	var file *os.File
	if file, err = ioutil.TempFile(os.TempDir(), "go-peerflix"); err != nil {
		return
	}

	defer func() {
		if _err := file.Close(); _err != nil {
			log.Printf("Error closing torrent file: %s", _err)
		}
	}()

	response, err := http.Get(URL)
	if err != nil {
		return
	}

	defer func() {
		if _err := response.Body.Close(); _err != nil {
			log.Printf("Error closing torrent file: %s", _err)
		}
	}()

	_, err = io.Copy(file, response.Body)

	return file.Name(), err
}

// NewFileReader sets up a torrent file for streaming reading.
func NewFileReader(f *torrent.File) (SeekableContent, error) {
	torrent := f.Torrent()

	if torrent == nil {
		return nil, errors.New("Not ready")
	}

	reader := torrent.NewReader()

	// We read ahead 1% of the file continuously.
	reader.SetReadahead(f.Length() / 100)
	reader.SetResponsive()
	_, err := reader.Seek(f.Offset(), os.SEEK_SET)

	return &FileEntry{
		File:   f,
		Reader: reader,
	}, err
}

func (c *Stream) Info() (*StreamInfo, error) {
	path := path.Join(c.Config.TorrentPath, filenameinfo)
	info := StreamInfo{}

	bytes, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(bytes, &info)
	if err != nil {
		return nil, err
	}

	info.Torrent = TorrentInfo{
		Percentage 	 : c.Percentage(),
		Speed 		 : c.Speed(),
		IsComplete 	 : c.IsComplete(),
		FileSize 	 : c.FileSize(),
		ReadyForPlayback : c.ReadyForPlayback(),
		FileName         : c.FileName(),
	}

	return &info, nil
}

//сохраняем информацию о стриме
func (c *Stream) SaveInfo (info *StreamInfo) error {
	bytes, err := json.Marshal(info)
	if err == nil {
		return ioutil.WriteFile(path.Join(c.Config.TorrentPath, filenameinfo), bytes, 0777)
	}

	return err
}

func (c *Stream) StartWithInfo (info *StreamInfo) error {
	err := c.Start(info.Link)
	if err != nil {
		return err
	}

	return c.SaveInfo(info)
}

func (c *Stream) Start (torrentPath string) error {
	var _t *torrent.Torrent
	var err error

	var cfg = c.Config
	var _c = c.Client

	c.Stop()

	// Add as magnet url.
	if strings.HasPrefix(torrentPath, "magnet:") {
		if _t, err = _c.AddMagnet(torrentPath); err != nil {
			return StreamError{Type: "adding torrent", Origin: err}
		}
	} else {
		// Otherwise add as a torrent file.

		// If it's online, we try downloading the file.
		if isHTTP.MatchString(torrentPath) {
			if torrentPath, err = downloadFile(torrentPath); err != nil {
				return StreamError{Type: "downloading torrent file", Origin: err}
			}
		}

		if _t, err = _c.AddTorrentFromFile(torrentPath); err != nil {
			return StreamError{Type: "adding torrent to the client", Origin: err}
		}
	}

	c.Torrent = _t
	c.Torrent.SetMaxEstablishedConns(cfg.MaxConnections)

	go func() {
		<-_t.GotInfo()
		_t.DownloadAll()

		// Prioritize first 5% of the file.
		c.getLargestFile().PrioritizeRegion(0, int64(_t.NumPieces()/100*5))
	}()

	return nil
}

func (c *Stream) Stop () {
	if c.Torrent != nil {
		c.Torrent.Drop()
		c.Torrent = nil
	}

	err := c.SaveInfo(&StreamInfo{})
	if err != nil {
		fmt.Print(err)
	}
}





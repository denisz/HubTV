package hub

import (
	"net/http"
	"encoding/json"
)

func ResponseWriterError (writer http.ResponseWriter, message string) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(500)
	bytes, _ := json.Marshal(struct{
		Error string
	}{ Error: message})
	writer.Write(bytes)
}


func ResponseSuccess (writer http.ResponseWriter, bytes []byte ) {
	writer.WriteHeader(200)
	writer.Header().Set("Content-Type", "application/json")
	writer.Write(bytes)
}
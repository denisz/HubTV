package main

import (
	"net"
	"errors"
	"fmt"
	"net/http"
	"hub"
	"log"
)


func main() {
	var portServer int = 8080
	var portTv int = 8081

	cfg := hub.NewServerConfig()

	server := hub.NewServer(cfg)
	defer server.Close()

	hub.NewRender(server)

	address, err := externalIP()
	if err != nil {
		address = "localhost"
	}


	go func () {
		tv := hub.NewSmartTvProxy()
		defer tv.Close()
		fmt.Printf("\tTv server is running at http://%s:%d \n", address, portTv)
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", portTv), tv.Router))
	}()

	fmt.Printf("The server is running at http://%s:%d \n", address, portServer)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", portServer), server.Router))
}


func externalIP() (string, error) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "", err
	}

	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 {
			continue // interface down
		}
		if iface.Flags&net.FlagLoopback != 0 {
			continue // loopback interface
		}
		addrs, err := iface.Addrs()
		if err != nil {
			return "", err
		}
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() {
				continue
			}
			ip = ip.To4()
			if ip == nil {
				continue // not an ipv4 address
			}
			return ip.String(), nil
		}
	}
	return "", errors.New("are you connected to the network?")
}

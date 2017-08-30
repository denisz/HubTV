//
//  MovieView.swift
//  PiP
//
//  Created by denis zaytcev on 2/2/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Cocoa
import SwiftyJSON
import Alamofire

let placeholderImage = NSImage(named: "noPicture")

class MovieView: NSView {
    @IBOutlet weak var picture: DKAsyncImageView!
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var rating: NSTextField!
    @IBOutlet weak var year: NSTextField!
    @IBOutlet weak var synopsis: NSTextField!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var statusView: StatusView!
    
    @IBOutlet weak var btn720p: NSBox!
    @IBOutlet weak var btn1080p: NSBox!
    
    var movie: JSON?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.updateFromStatus()
        
        let center = NotificationCenter.default
        let update = Notification.Name(kStatusActionUpdate)
        
        center.addObserver(self, selector: #selector(self.updateFromStatus),name: update,object: nil)
    }
    
    func LoadMovie (_ movie: JSON, torrent: JSON?) {
        self.picture.downloadImageFromURL(movie["Poster"].stringValue, placeHolderImage: placeholderImage, errorImage: placeholderImage, usesSpinningWheel: false)
        
        
        let title = movie["Title"].stringValue
        if !title.isEmpty {
            self.title.stringValue = title
        } else {
            if let torrent = torrent {
                self.title.stringValue = torrent["FileName"].stringValue
            }
        }
        
        self.synopsis.stringValue   = movie["Synopsis"].string ?? "N/A"
        self.rating.stringValue     = movie["Rating"].stringValue
        self.year.stringValue       = movie["Year"].stringValue
        
        self.movie = movie
        
        self.btn720p.isHidden = true
        self.btn1080p.isHidden = true
        
        if let torrents = movie["Torrents"].array {
            self.btn720p.isHidden = torrents.first(where: { (model) -> Bool in
                return model["Quality"].stringValue == "720p"
            }) == nil
            
            self.btn1080p.isHidden = torrents.first(where: { (model) -> Bool in
                return model["Quality"].stringValue == "1080p"
            }) == nil
        }
    }
    
    func playMovieWithQuality (quality: String) {
        guard let movie = self.movie, let id = movie["ID"].number else {return}

        Alamofire.request(Router.start(quality, id.stringValue))
            .responseJSON { response in
                switch response.result {
                case .success( _):
                    _ = self.statusView.update()
                case .failure(let error):
                    Swift.print(error)
                    //show alert
                }
        }
    }
    
    @IBAction public func didTapPlay720p(_ sender: AnyObject) {
        self.playMovieWithQuality(quality: "720p")
    }
    
    @IBAction public func didTapPlay1080p(_ sender: AnyObject) {
        self.playMovieWithQuality(quality: "1080p")
    }
    
    func updateFromStatus() {
        self.statusView.update().responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value).dictionaryValue
                if let movie = json["Movie"], !(movie.null != nil) {
                    self.LoadMovie(movie, torrent: json["Torrent"])
                }
            case .failure(let error):
                Swift.print(error)
            }
        }
    }
}

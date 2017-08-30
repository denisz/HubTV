//
//  StatusView.swift
//  PiP
//
//  Created by denis zaytcev on 2/14/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

func humanReadableByteCount(size: Int64) -> String {
    return ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
}

extension Int {
    func format(f: String) -> String {
        return String(format: "%\(f)d", self)
    }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}


class StatusView: NSView {
    @IBOutlet weak var status: NSTextField!
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var play: NSButton!
    
    var interval: Timer?
    var currentRequest: DataRequest?
    
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.progress.minValue = 0
        self.progress.maxValue = 100
        self.tick()
    }
    
    func tick () {
        self.update()
            .responseJSON { (response) in
                self.interval = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.tick), userInfo: nil, repeats: false)
            }
    }
    
    public func update () -> DataRequest {
        if let request = self.currentRequest {
            return request
        }
        
        self.currentRequest = Alamofire.request(Router.status)
            .responseJSON { (response) in
                defer {
                    self.currentRequest = nil
                }
                
                switch response.result {
                case .success(let value):
                    let json = JSON(value).dictionaryValue
                    
                    guard let movie = json["Movie"],
                        let torrent = json["Torrent"] else {
                            return
                            
                    }
                    
                    let isComplete  = torrent["IsComplete"].boolValue
                    let isReady     = torrent["ReadyForPlayback"].boolValue
                    let speed       = torrent["Speed"].numberValue
                    let percent     = torrent["Percentage"].numberValue
                    let fileSize    = torrent["FileSize"].int64Value
                    let title       = movie["Title"].stringValue
                    
                    if !title.isEmpty {
                        self.title.stringValue = title
                    } else {
                        self.title.stringValue = torrent["FileName"].stringValue
                    }
                    
                    if isComplete {
                        self.status.stringValue = "Complete"
                    } else {
                        let _percent = percent.doubleValue / Float64(100.0)
                        let remaining = Double(fileSize) * _percent
                        let _remainig = humanReadableByteCount(size: Int64(remaining))
                        let _total = humanReadableByteCount(size: fileSize)
                        let _speed = humanReadableByteCount(size: speed as! Int64)
                        self.status.stringValue = "\(_remainig) of \(_total) (\(percent.doubleValue.format(f: ".1"))%) \(_speed)/s"
                    }
                    
                    self.progress.doubleValue = percent.doubleValue
                    self.play.isEnabled = isReady
                    
                case .failure(let error):
                    Swift.print(error)
                }
        }
        
        return self.currentRequest!
    }
    
    @IBAction public func didTapStop(_ sender: AnyObject) {
        let center = NotificationCenter.default
        let notify = Notification.Name(kPlayerActionStop)
        
        Alamofire.request(Router.stop)
            .responseJSON { response in
                center.post(name: notify, object: nil)
                _ = self.update()
            }
    }
    
    @IBAction public func didTapPlay(_ sender: AnyObject) {
        let center = NotificationCenter.default
        let notify = Notification.Name(kPlayerActionPlay)
        center.post(name: notify, object: nil)
    }
}

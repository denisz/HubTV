//
//  PlayerView.swift
//  PiP
//
//  Created by denis zaytcev on 2/2/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Cocoa
import SwiftyJSON
import Alamofire
import Gzip

typealias SliderHandlerChanged = (Double)->Void

class MySlider: NSSlider {
    var dragging: Bool = false
    
    var handlerChanged: SliderHandlerChanged?
    
    override func mouseUp(with event: NSEvent) {
        self.dragging = true
        super.mouseUp(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.dragging = false
        super.mouseDown(with: event)
        self.handlerChanged?(self.doubleValue)
    }
}

class PlayerView: NSView {
    @IBOutlet weak var play: NSButton!
    @IBOutlet weak var progress: MySlider!
    @IBOutlet weak var controls: NSView!
    @IBOutlet weak var remainingTime: NSTextField!
    @IBOutlet weak var time: NSTextField!
    
    var interval: Timer?
    var progressDrag: Bool = false
    var playing: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.viewDidLoad()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewDidLoad()
    }
    
    func viewDidLoad() {
        let center = NotificationCenter.default
        let changed = Notification.Name(VLCMediaPlayerTimeChanged)
        let playing = Notification.Name(kPlayerActionPlaying)
        let paused = Notification.Name(kPlayerActionPaused)
        
        center.addObserver(self, selector: #selector(self.playerTimeChanged(_:)),name: changed,object: nil)
        center.addObserver(self, selector: #selector(self.playerPlaying(_:)), name: playing, object: nil)
        center.addObserver(self, selector: #selector(self.playerPaused(_:)), name: paused, object: nil)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.controls.isHidden = true
        self.controls.wantsLayer = true
        self.controls.layer?.zPosition = 2
        
        self.progress.minValue = 0
        self.progress.maxValue = 1
        self.progress.target = self
        self.progress.handlerChanged = self.onProgressChange
        self.progress.isContinuous = false
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        let options : NSTrackingAreaOptions = [.enabledDuringMouseDrag, .mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseExited(with event: NSEvent) {
        
        let animation = NSViewAnimation(viewAnimations: [
                [ NSViewAnimationTargetKey: self.controls,
                  NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect ]
            ])
        
        animation.duration = 0.3
        animation.start()
    }
    
    override func mouseEntered(with event: NSEvent) {
        let animation = NSViewAnimation(viewAnimations: [
            [ NSViewAnimationTargetKey: self.controls,
              NSViewAnimationEffectKey: NSViewAnimationFadeInEffect ]
            ])
        
        animation.duration = 0.3
        animation.start()
    }
    
    @IBAction public func didTapPIP(_ sender: AnyObject) {
        let center = NotificationCenter.default
        let notify = Notification.Name(kPlayerActionPIP)
        center.post(name: notify, object: nil)
    }
    
    @IBAction public func didTapSubtitles (_ sender: AnyObject) {
        Alamofire.request(Router.subtitles)
            .validate(statusCode: 200..<300)
             .validate(contentType: ["application/zip"])
            .responseData(completionHandler: { (response) in
                switch response.result {
                case .success(let data):
                    var decompressedData: Data?
                    
                    if data.isGzipped {
                        decompressedData = try! data.gunzipped()
                    } else {
                        decompressedData = data
                    }
                    
                    let datastring = String(data: decompressedData!, encoding: .utf8)
                    let notify = Notification.Name(kPlayerActionSubtitles)
                    NotificationCenter.default.post(name: notify, object: datastring)
                case .failure(let error):
                    Swift.print(error)
                }
            })
    }
    
    @IBAction public func didTapPause(_ sender: AnyObject) {
        let center = NotificationCenter.default
        let notify = Notification.Name(kPlayerActionPause)
        center.post(name: notify, object: nil)
    }
    
    @IBAction public func didTapPlay(_ sender: AnyObject) {
        let center = NotificationCenter.default
        var notify: Notification.Name?
        
        if playing {
            notify = Notification.Name(kPlayerActionPause)
        } else {
            notify = Notification.Name(kPlayerActionResume)
        }
        
        if let notify = notify {
            center.post(name: notify, object: nil)
        }
    }
    
    func playerPlaying(_ notify: Notification) {
        self.playing = true
        self.play.image = NSImage(named: "ic_pause")
    }
    
    func playerPaused(_ notify: Notification) {
        self.playing = false
        self.play.image = NSImage(named: "ic_play_arrow")
    }
    
    func playerTimeChanged(_ notify: Notification) {
        if let player = notify.object as? VLCMediaPlayer {
            self.remainingTime.stringValue = player.remainingTime.stringValue
            self.time.stringValue = player.time.stringValue
            if !self.progress.dragging {
                self.progress.doubleValue = Double(player.position)
            }
        }
    }
    
    func onProgressChange(value: Double) {
        Swift.print(value)
    }
}

//
//  PlayerViewController.swift
//  PiP Client
//
//  Created by Guilherme Rambo on 26/12/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

import PIPContainer
import AVFoundation
import VLCKit



class PlayerViewController: NSViewController {
    @IBOutlet weak var subtitlesLabels: NSTextField!
    @IBOutlet weak var videoView: VLCVideoView!
    
    fileprivate var player: VLCMediaPlayer!
    
    private var timer: Timer!
    
    private var subtitles: Subtitles!
    
    public var isEnableSubtitles: Bool = true
    
    private var pip: PIPContainerViewController? {
        return parent as? PIPContainerViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let timer = Timer(timeInterval: 0.5,
                          target: self,
                          selector:  #selector(self.currentProgressionUpdated),
                          userInfo: nil,
                          repeats: true)
        
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        
        self.timer = timer
        self.subtitles = Subtitles.instanceShared
        
        let back = NSColor(red:0.20, green:0.20, blue:0.21, alpha:1.00)
        
        self.view.layer?.backgroundColor = back.cgColor
        self.pip?.view.layer?.backgroundColor = back.cgColor
        
        self.videoView.backColor = back //NSColor.black
        self.videoView.fillScreen = true
        
        self.videoView.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
        self.view.addSubview(self.videoView)
        self.view.wantsLayer = true
        
        self.player = VLCMediaPlayer(videoView: self.videoView)
        self.player.delegate = self
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(self.play),      name: NSNotification.Name(kPlayerActionPlay), object: nil)
        
        center.addObserver(self, selector: #selector(self.resume),      name: NSNotification.Name(kPlayerActionResume), object: nil)
        
        center.addObserver(self, selector: #selector(self.stop),      name: NSNotification.Name(kPlayerActionStop), object: nil)
        
        center.addObserver(self, selector: #selector(self.pause),     name: NSNotification.Name(kPlayerActionPause), object: nil)
        
        center.addObserver(self, selector: #selector(self.togglePIP), name: NSNotification.Name(kPlayerActionPIP), object: nil)
        
        center.addObserver(self, selector: #selector(self.loadSubtitles(_:)), name: NSNotification.Name(kPlayerActionSubtitles), object: nil)
    }
    
    public func togglePIP () {
        self.pip?.togglePIP(nil)
    }
    
    public func stop () {
        self.player?.pause()
    }
    
    public func seek (_ notify: Notification) {
    }
    
    public func pause() {
        self.player?.pause()
    }
    
    public func resume() {
        self.player?.play()
    }
    
    public func play() {
        guard let url = try? Router.file.asURLRequest().url! as URL else {return}
        
        let media = VLCMedia(url: url)
        player?.media = media
        player?.play()
        
        subtitlesLabels.stringValue = ""
        subtitlesLabels.layer?.zPosition = 1

        self.subtitles.clean()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupPIPSupport()
    }
    
    func currentProgressionUpdated () {
        if let time = self.player?.time {
            self.subtitlesLabels.stringValue = self.subtitles.time(time.intValue.msToSeconds)
        }
    }
    
    private func setupPIPSupport() {
        pip?.pipWillOpen = { [weak self] in
            guard let rate = self?.player?.rate else { return }
            
            self?.pip?.isPlaying = (rate != 0.0)
        }
        
        pip?.pipDidPause = { [weak self] in
            self?.player?.pause()
        }
        
        pip?.pipDidPlay = { [weak self] in
            self?.player?.play()
        }
    }
    
    func loadSubtitles(_ notify: Notification) {
        if let payload = notify.object as? String {
            self.subtitles.load(payload)
        }
    }

}

extension PlayerViewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        if let player = self.player {
            let center = NotificationCenter.default
            var notify: Notification.Name?
            
            if player.isPlaying {
                notify = Notification.Name(kPlayerActionPlaying)
            } else {
                notify = Notification.Name(kPlayerActionPaused)
            }
            
            if let notify = notify {
                center.post(name: notify, object: nil)
            }
        }
    }
}


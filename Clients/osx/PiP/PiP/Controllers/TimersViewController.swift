//
//  TimersViewController.swift
//  PiP
//
//  Created by denis zaytcev on 3/6/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Foundation
import Cocoa

class MyTimerSlider: NSSlider {
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



class TimersViewController: NSViewController {
    @IBOutlet weak var slider: MyTimerSlider!
    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.slider.handlerChanged = self.onProgressChange
        
        let value = Subtitles.instanceShared.offset
        self.slider.doubleValue = value
        self.label.stringValue  = "\(value.format(f: ".0"))s"
    }
    
    func onProgressChange(value: Double) {
        Subtitles.instanceShared.offset = value
        self.label.stringValue = "\(value.format(f: ".0"))s"
    }
    
}

//
//  MyWindow.swift
//  PiP Client
//
//  Created by denis zaytcev on 1/30/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Foundation
import Cocoa

class MyWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: [.titled, .resizable, .miniaturizable, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        
        self.contentView!.wantsLayer = true;/*this can and is set in the view*/
        
        self.delegate = self
        self.isOpaque = false
        self.makeKeyAndOrderFront(nil)//moves the window to the front
        self.titlebarAppearsTransparent = true
        self.center()
        self.isMovableByWindowBackground = true
    }
}


extension MyWindow: NSWindowDelegate {
//    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "windowWillReturnFieldEditor"), object: nil)
//    }
}

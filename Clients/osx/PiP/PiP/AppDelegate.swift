//
//  AppDelegate.swift
//  PiP
//
//  Created by denis zaytcev on 1/30/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Cocoa
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {}

    func applicationWillTerminate(_ aNotification: Notification) {}
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleGetURL(event:reply:)), forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL) )
    }
    
    func handleGetURL(event: NSAppleEventDescriptor, reply:NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue {
            Alamofire.request(Router.stream(urlString))
                .responseJSON(completionHandler: { (response) in
                    let center = NotificationCenter.default
                    let update = Notification.Name(kStatusActionUpdate)
                    center.post(name: update, object: nil)
                })
        }
    }
}


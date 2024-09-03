//
//  AppDelegate.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var controller = OverlayController()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        controller.runApp()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
        controller.stopTimer()
        controller.deleteAll()
        
    }
    
}

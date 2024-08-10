//
//  WindowManager.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/23/24.
//

import Cocoa
import SwiftUI

class WindowManager: ObservableObject {
    
    static let shared = WindowManager()
    //private var overlayWindow: NSWindow?
    private var overlayWindow: NSPanel?
    
    func createOverlayWindow(with appDelegate: AppDelegate) {
        
        guard let frame = AccessibilityManager.shared.getMainWindowFrame() else { return }
        
        if let existingWindow = overlayWindow {
            existingWindow.setFrame(frame, display: true)
        } else {
            let panel = NSPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .screenSaver
            panel.ignoresMouseEvents = true
            
            let contentView = NSHostingView(rootView: OverlayContentView(appDelegate: appDelegate))
            panel.contentView = contentView
            
            panel.orderFront(nil)
            overlayWindow = panel
            
        }
        
        /*
        
        // Removes existing overlay window, if one exists
        //overlayWindow?.close()
        
        // Defines the active monitor size, and grabs the position of the active element
        let screenFrame = NSScreen.main?.frame ?? .zero
        let windowPosition = NSPoint(x: position.x, y: screenFrame.height - position.y - size.height)
        
        // Creates the overlay window with the value of windowPosition
        let window = NSWindow(
            contentRect: NSRect(origin: windowPosition, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        
        let contentView = NSHostingView(rootView: OverlayContentView(appDelegate: appDelegate))
        window.contentView = contentView
        
        window.orderFront(nil)
        overlayWindow = window
        */
    }
}


    
    /*
    private var borderWindows: [NSPanel] = []
    
    init() {}
    
     
    func createNewWindow(at position: NSPoint, with size: CGSize, with appDelegate: AppDelegate) {
        
        for window in borderWindows {
            window.orderOut(nil)
        }
        borderWindows.removeAll()
        
        /*
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        let maxX = screenFrame.maxX - size.width
        let maxY = screenFrame.maxY - size.height
        
        let windowX = min(max(position.x, screenFrame.minX), maxX)
        let windowY = min(max(screenFrame.maxY - position.y - size.height, screenFrame.minY), maxY)
        
        let window = NSPanel(
            contentRect: NSRect(origin: NSPoint(x: windowX, y: windowY), size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        
        let borderView = BorderView(frame: NSRect(origin: .zero, size: size))
        window.contentView = borderView
        
        window.orderFront(nil)
        
        borderWindows.append(window)
        */
         
        
        let screenFrame = NSScreen.main?.frame ?? .zero
        let windowPosition = NSPoint(x: position.x, y: screenFrame.height - position.y - size.height)
        
        let window = NSPanel(
            contentRect: NSRect(origin: windowPosition, size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        
        let borderView = BorderView(frame: NSRect(origin: .zero, size: size))
        //borderView.role = appDelegate.focusedElementRole
        window.contentView = borderView
        
        window.orderFront(nil)
        
        borderWindows.append(window)
         
        
    }
}
     */

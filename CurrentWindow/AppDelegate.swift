//
//  AppDelegate.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    static let shared = AppDelegate()
    private var controller = OverlayController.shared
    
    private var windowActivationObserver: NSObjectProtocol?
    private var windowDeactivationObserver: NSObjectProtocol?

    private var axObserver: AXObserver?
    
    private var runAppTimer: Timer?
        
    internal func applicationDidFinishLaunching(_ notification: Notification) {
        
        //setUpWindowActivationObserver()
        //setUpWindowDeactivationObserver()
        //setUpTextObserver()
        //controller.runApp()
        controller.test_start()
    }

    internal func applicationWillTerminate(_ aNotification: Notification) {
        
        controller.deleteAll()
        if let axObserver = axObserver {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(axObserver), .defaultMode)
        }
    }
    
    private func setUpWindowActivationObserver() {
        
        windowActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("Focus Changed")
            self?.controller.runApp()
            self?.setUpTextObserver()
        }
    }
    
    private func setUpWindowDeactivationObserver() {
        windowDeactivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("Window closed")
            self?.controller.deleteAll()
        }
    }
    
    private func setUpTextObserver() {
            
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        
        if let existingObserver = axObserver {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(existingObserver), .defaultMode)
        }
            
        var observer: AXObserver?
        let error = AXObserverCreate(pid, { (observer, element, notification, refcon) in
            guard let refcon = refcon else { return }
            let this = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
            this.handleNotification(element: element, notification: notification)
        }, &observer)
            
        guard error == .success, let observer = observer else { return }
        axObserver = observer
            
        let (focusedWindow, focusedElement) = controller.getFocusedApp()
        
        AXObserverAddNotification(observer, focusedElement, kAXFocusedUIElementChangedNotification as CFString, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        AXObserverAddNotification(observer, focusedElement, kAXValueChangedNotification as CFString, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        AXObserverAddNotification(observer, focusedWindow, kAXWindowMovedNotification as CFString, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        AXObserverAddNotification(observer, focusedWindow, kAXWindowResizedNotification as CFString, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        AXObserverAddNotification(observer, focusedWindow, kAXWindowMiniaturizedNotification as CFString, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }
        
    private func handleNotification(element: AXUIElement, notification: CFString) {
        
        controller.deleteAll()

        runAppTimer?.invalidate()
        
        runAppTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] runAppTimer in
            self?.controller.runApp()
        }
    }
}

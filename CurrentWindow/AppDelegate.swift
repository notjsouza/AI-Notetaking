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
        
        setUpWindowActivationObserver()
        setUpWindowDeactivationObserver()
                
        Task { @MainActor in
            controller.start()
        }
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
            //self?.controller.clearBorders()
            guard let focusedWindow = self?.controller.getActiveWindow() else { return }
            self?.findScrollBar(element: focusedWindow)
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
    
    private func findScrollBar(element: AXUIElement) {
                
        var roleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String else { return }
        
        if role.lowercased().contains("scrollbar") {
            
            setUpScrollBarObserver(element: element)
                
        }
         
        var childRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childRef) == .success,
              let children = childRef as? [AXUIElement] else { return }
        
        for child in children {
            findScrollBar(element: child)
        }
        
    }
    
    private func setUpScrollBarObserver(element: AXUIElement) {
        
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
        
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let addNotification = { (element: AXUIElement, notification: CFString) in
            let error = AXObserverAddNotification(observer, element, notification, refcon)
            if error != .success {
                print("Failed to add notification: \(notification)")
            }
        }
        
        addNotification(element, kAXValueChangedNotification as CFString)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }
    
    private func setUpTextObserver() {
        
            guard let app = NSWorkspace.shared.frontmostApplication else {
                print("No frontmost application found")
                return
            }
            let pid = app.processIdentifier
            let appElement = AXUIElementCreateApplication(pid)
            
            if let existingObserver = axObserver {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(existingObserver), .defaultMode)
            }
                
            var observer: AXObserver?
            let error = AXObserverCreate(pid, { (observer, element, notification, refcon) in
                guard let refcon = refcon else { return }
                let this = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                this.handleNotification(element: element, notification: notification)
            }, &observer)
                
            guard error == .success, let observer = observer else {
                print("Failed to create AXObserver")
                return
            }
            axObserver = observer
                
            guard let focusedWindow = controller.getActiveWindow() else {
                print("No active window found")
                return
            }
            
            var focusedElementRef: CFTypeRef?
            let elementError = AXUIElementCopyAttributeValue(
                appElement,
                kAXFocusedUIElementAttribute as CFString,
                &focusedElementRef
            )
            
            guard elementError == .success,
                  let focusedElementRef = focusedElementRef,
                  let focusedElement = focusedElementRef as! AXUIElement? else {
                print("Failed to get focused element")
                return
            }
            
            let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let addNotification = { (element: AXUIElement, notification: CFString) in
                let error = AXObserverAddNotification(observer, element, notification, refcon)
                if error != .success {
                    print("Failed to add notification: \(notification)")
                }
            }
            
            addNotification(focusedElement, kAXFocusedUIElementChangedNotification as CFString)
            addNotification(focusedElement, kAXValueChangedNotification as CFString)
            addNotification(focusedWindow, kAXWindowMovedNotification as CFString)
            addNotification(focusedWindow, kAXWindowResizedNotification as CFString)
            addNotification(focusedWindow, kAXWindowMiniaturizedNotification as CFString)
            
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

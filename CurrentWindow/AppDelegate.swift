//
//  AppDelegate.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    @Published var activeTextField: String = ""
    
    private var applicationSwitchObserver: NSObjectProtocol?
    private var axObserver: AXObserver?
    
    deinit {
        
        removeObservers()
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        AccessibilityManager.shared.appDelegate = self
        startObservingApplicationSwitch()
        observeCurrentApplication()
        checkCurrentTextFieldValue()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
        removeObservers()
        
    }
    
    func checkCurrentTextFieldValue() {
        
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(axApp, 
                                                kAXFocusedUIElementAttribute as CFString,
                                                &focusedElement
        )
        
        if res == .success, let element = focusedElement as! AXUIElement? {
            
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(
                element,
                kAXValueAttribute as CFString,
                &value
            )
            
            let newValue = (value as? String) ?? ""
            
            if newValue != activeTextField {
                
                activeTextField = newValue
                print(activeTextField)
                
                if let wordFrames = AccessibilityManager.shared.getWordFrames() {
                        
                    WindowManager.shared.createOverlayWindow(wordFrames: wordFrames)
                        
                }
                
            }
            
        }
        
    }
    
    func startObservingApplicationSwitch() {
        
        applicationSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
        
            self?.observeCurrentApplication()
            
        }
        
    }
    
    func observeCurrentApplication() {
        
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        
        if let existingObserver = self.axObserver {
            
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
                                  AXObserverGetRunLoopSource(existingObserver),
                                  .defaultMode
            )
            self.axObserver = nil
            
        }
        
        var axObserver: AXObserver?
        let callback: AXObserverCallback = { (observer, element, notification, refcon) in
            
            NotificationCenter.default.post(name: .axNotificationRecieved, object: nil)
            
        }
        
        let createObserverResult = AXObserverCreate(pid,
                                                    callback,
                                                    &axObserver
        )
        
        if createObserverResult == .success, let axObserver = axObserver {
            
            self.axObserver = axObserver
            AXObserverAddNotification(axObserver,
                                      axApp,
                                      kAXFocusedUIElementChangedNotification as CFString,
                                      nil
            )
            
            AXObserverAddNotification(axObserver, 
                                      axApp,
                                      kAXValueChangedNotification as CFString,
                                      nil
            )
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(),
                               AXObserverGetRunLoopSource(axObserver),
                               .defaultMode
            )
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleAXNotification),
                                                   name: .axNotificationRecieved,
                                                   object: nil
            )
            
        }
        
    }

    @objc func handleAXNotification() {
        
        checkCurrentTextFieldValue()
        
    }
    
    func removeObservers() {
        
        if let observer = applicationSwitchObserver {
            
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            applicationSwitchObserver = nil
            
        }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .axNotificationRecieved,
                                                  object: nil
        )
         
        if let axObserver = axObserver {
            
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(axObserver), .defaultMode)
            self.axObserver = nil
            
        }
                
    }
    
}

extension Notification.Name {
    
    static let axNotificationRecieved = Notification.Name("AXNotificationRecieved")
    
}

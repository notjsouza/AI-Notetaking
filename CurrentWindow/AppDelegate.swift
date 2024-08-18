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
        
        if !AccessibilityManager.shared.isAccessibilityEnabled() {
            
            showAccessibilityAlert()
            
        }
        
        //AccessibilityManager.shared.appDelegate = self
        startObservingApplicationSwitch()
        observeCurrentApplication()
        checkCurrentTextFieldValue()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
        removeObservers()
        WindowManager.shared.removeAllOverlays()
        
    }
    
    func checkCurrentTextFieldValue() {
        
        guard let (newValue, elementFrame, _) = AccessibilityManager.shared.getFocusedTextFieldInfo() else { return }
        
        if newValue != activeTextField {
                
            activeTextField = newValue
            print(activeTextField)
                
            let tempTextField = NSTextField(frame: elementFrame)
            tempTextField.stringValue = activeTextField
                
            print("elementFrame: \(elementFrame)")
            
            WindowManager.shared.createOverlayWindows()
            
            /*
            WindowManager.shared.createOverlayWindows(
                for: tempTextField, 
                elementFrame: elementFrame
            )
             */
            
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
    
    func showAccessibilityAlert() {
        
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "This app requires accessibility permissions to function properly. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
            
        }
        
    }
    
}

extension Notification.Name {
    
    static let axNotificationRecieved = Notification.Name("AXNotificationRecieved")
    
}

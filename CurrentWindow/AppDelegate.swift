//
//  AppDelegate.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    //@Published var curAppName: String = ""
    @Published var activeTextField: String = ""
    
    //@Published var focusedElementFrame: CGRect?
    //@Published var focusedElementRole: String?
    
    //var windowObserver: NSObjectProtocol?
    //var focusObserver: AXObserver?
    
    private var timer: Timer?

    deinit {
        timer?.invalidate()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AccessibilityManager.shared.appDelegate = self
        
        /*
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            AccessibilityManager.shared.getFocusedWindowElements()
        }
        
        updateCurrentApp()
        setUpObserver()
        setUpFocusObserver()
         */
        startTimer()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        /*
        if let observer = windowObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        if let observer = focusObserver {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        */
        timer?.invalidate()
    }
    
    func checkCurrentTextFieldValue() {
        
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if res == .success, let element = focusedElement as! AXUIElement? {
            var value: AnyObject?
            AXUIElementCopyAttributeValue(
                element,
                kAXValueAttribute as CFString,
                &value
            )
            activeTextField = (value as? String) ?? ""
            WindowManager.shared.createOverlayWindow(with: self)
            //handleFocusChange(element: element)
        }
        
    }
    
    func startTimer() {
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkCurrentTextFieldValue()
        }
        
    }
    
    /*
    func updateCurrentApp() {
        let app = NSWorkspace.shared.frontmostApplication
        curAppName = app?.localizedName ?? ""
    }
    
    func setUpObserver() {
        windowObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.updateCurrentApp()
                AccessibilityManager.shared.getFocusedWindowElements()
            }
        }
    }
    
    func setUpFocusObserver() {
        
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        
        var observer: AXObserver?
        let error = AXObserverCreate(pid, { (observer, element, notification, refcon) in
            guard let appDelegate = refcon?.load(as: AppDelegate.self) else { return }
            appDelegate.handleFocusChange(element: element)
        }, &observer)
        
        guard error == .success, let observer = observer else { return }
        
        focusObserver = observer
        
        let axApp = AXUIElementCreateApplication(pid)
        AXObserverAddNotification(observer, axApp, kAXFocusedUIElementChangedNotification as CFString, nil)
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        
    }
    
    func handleFocusChange(element: AXUIElement) {
        
        updateFocusedElementInfo(element: element)
        
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        
        let newText = (value as? String) ?? ""
        
        if newText != activeTextField {
            activeTextField = newText
            print("Text changed, new value: ")
            print(activeTextField)
        }
        
        updateBorderWindow()
        
        /*
         
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
         
        if let roleString = role as? String,
           roleString == "AXTextField" || roleString == "AXTextArea" {
            
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
            
            let newText = (value as? String) ?? ""
            
            if newText != activeTextField {
                activeTextField = newText
                print("Text changed, new value: ")
                print(activeTextField)
            }
            
        } else {
            
            if !activeTextField.isEmpty {
                print("Text field lost focus, last value: \(activeTextField)")
            }
            
            activeTextField = ""
        }
        */
    }
    
    func updateFocusedElementInfo(element: AXUIElement) {
        
        var role: CFTypeRef?
        var position: CFTypeRef?
        var size: CFTypeRef?
        
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size)
        
        focusedElementRole = role as? String
        
        if let positionValue = position as! AXValue?,
           let sizeValue = size as! AXValue? {
            
            var point = CGPoint.zero
            var sizeRect = CGSize.zero
            
            AXValueGetValue(positionValue, .cgPoint, &point)
            AXValueGetValue(sizeValue, .cgSize, &sizeRect)
            
            focusedElementFrame = CGRect(origin: point, size: sizeRect)
            
        } else {
            
            focusedElementFrame = nil
            
        }
    }
    
    func updateBorderWindow() {
        if let frame = focusedElementFrame {
            WindowManager.shared.createOverlayWindow(at: frame.origin, with: frame.size, with: self)
        }
    }
    */
    
}

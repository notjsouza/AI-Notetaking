//
//  AppDelegate.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    @Published var activeTextField: String = ""
    @Published var bounds: CGRect?
    //@Published var element: AXUIElement?
    
    private var timer: Timer?
    private var isBorderDrawn = false
    
    deinit {
        
        timer?.invalidate()
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        AccessibilityManager.shared.appDelegate = self
        startTimer()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
        timer?.invalidate()
        WindowManager.shared.deleteTextOverlay()
        WindowManager.shared.deleteBorderOverlay()
        
    }
    
    func startTimer() {
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
        
            self?.checkCurrentTextFieldValue()
            
        }
        
    }
    
    func checkCurrentTextFieldValue() {
        
        guard let (curValue, curElement, curBounds) = AccessibilityManager.shared.getTextFieldData() else { return }
        
        if curValue != activeTextField {
                
            activeTextField = curValue
            print(activeTextField)
            
            WindowManager.shared.deleteTextOverlay()
            WindowManager.shared.createOverlay(text: activeTextField, element: curElement)

        }
        
        if curBounds != bounds {
            
            // ADJUST THIS FOR THE PORTION THAT IS IN VIEW
            // in the case where there's a scrollbar it's typically going offscreen
            
            bounds = curBounds
            //print(curBounds)

            WindowManager.shared.createBorderOverlay(for: curBounds)
    
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

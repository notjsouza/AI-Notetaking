//
//  AccessibilityManager.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import Cocoa
import CoreGraphics
import ApplicationServices

class AccessibilityManager {
    
    static let shared = AccessibilityManager()
    weak var appDelegate: AppDelegate?
    
    func isAccessibilityEnabled() -> Bool {
        
        return AXIsProcessTrusted()
        
    }
    
    func getMainWindowFrame() -> CGRect? {
        
        // Defines app as the focused application
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        // Grabs the PID of app, and creates an accessibility object using the pid of the focused application
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowRef: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(
            appElement,
            kAXMainWindowAttribute as CFString,
            &windowRef
        )
        guard res == .success, let windowElement = windowRef as! AXUIElement? else { return nil }
        
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        let positionRes = AXUIElementCopyAttributeValue(
            windowElement,
            kAXPositionAttribute as CFString,
            &positionRef
        )
        
        let sizeRes = AXUIElementCopyAttributeValue(
            windowElement,
            kAXSizeAttribute as CFString,
            &sizeRef
        )
        
        guard positionRes == .success, let position = positionRef as! AXValue? else { return nil }
        guard sizeRes == .success, let size = sizeRef as! AXValue? else { return nil }
        
        var cgPoint = CGPoint.zero
        var cgSize = CGSize.zero
        
        AXValueGetValue(
            position,
            .cgPoint,
            &cgPoint
        )
        
        AXValueGetValue(
            size,
            .cgSize,
            &cgSize
        )
        
        return CGRect(origin: cgPoint, size: cgSize)
        
    }
    
    func getTextFieldData() -> (String, AXUIElement, CGRect)? {
        
        // Defines app as the focused application
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        // Grabs the PID of app, and creates an accessibility object using the pid of the focused application
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard res == .success, let element = focusedElement as! AXUIElement? else { return nil }
        
        var valueRef: CFTypeRef?
        let valueRes = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueRef
        )
        guard valueRes == .success, let value = valueRef as? String else { return nil }
        
        
        // CHECK HERE IF ANY PROBLEMS
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
            let positionValue = positionRef as! AXValue?,
            let sizeValue = sizeRef as! AXValue? else { return nil }
                
        var position = CGPoint.zero
        var size = CGSize.zero
                
        AXValueGetValue(positionValue, .cgPoint, &position)
        AXValueGetValue(sizeValue, .cgSize, &size)
                
        let elementBounds = CGRect(origin: position, size: size)
        
        return (value, element, elementBounds)
        
    }
    
}

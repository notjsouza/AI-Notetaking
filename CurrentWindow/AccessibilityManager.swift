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
        AXUIElementCopyAttributeValue(
            appElement,
            kAXMainWindowAttribute as CFString,
            &windowRef
        )
        
        guard let window = windowRef as! AXUIElement? else { return nil }
        
        var position: AnyObject?
        var size: AnyObject?
        
        AXUIElementCopyAttributeValue(
            window,
            kAXPositionAttribute as CFString,
            &position
        )
        
        AXUIElementCopyAttributeValue(
            window,
            kAXSizeAttribute as CFString,
            &size
        )
        
        guard let positionValue = position as! AXValue?,
              let sizeValue = size as! AXValue? else { return nil }
        
        var cgPoint = CGPoint.zero
        var cgSize = CGSize.zero
        
        AXValueGetValue(
            positionValue,
            .cgPoint,
            &cgPoint
        )
        
        AXValueGetValue(
            sizeValue,
            .cgSize,
            &cgSize
        )
        
        return CGRect(origin: cgPoint, size: cgSize)
        
    }
    
    func getFocusedTextFieldInfo() -> (String, CGRect, CGRect)? {
        
        // Defines app as the focused application
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        // Grabs the PID of app, and creates an accessibility object using the pid of the focused application
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        ) == .success,
              let element = focusedElement as! AXUIElement? else { return nil }
            
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueRef
        ) == .success,
              let stringValue = valueRef as? String else { return nil }
        
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
        
        var windowRef: CFTypeRef?
        AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowAttribute as CFString,
            &windowRef
        )
        
        var windowPosition = CGPoint.zero
        var windowSize = CGSize.zero
        
        if let window = windowRef as! AXUIElement? {
            
            var windowPositionRef: CFTypeRef?
            var windowSizeRef: CFTypeRef?
            
            AXUIElementCopyAttributeValue(
                window,
                kAXPositionAttribute as CFString,
                &windowPositionRef
            )
            AXUIElementCopyAttributeValue(
                window,
                kAXSizeAttribute as CFString,
                &windowSizeRef
            )
            
            if let posValue = windowPositionRef as! AXValue?,
               let sizeValue = windowSizeRef as! AXValue? {
                
                AXValueGetValue(posValue, .cgPoint, &windowPosition)
                AXValueGetValue(sizeValue, .cgSize, &windowSize)
                
            }
            
        }
        
        let windowFrame = CGRect(origin: windowPosition, size: windowSize)
        
        return (stringValue, elementBounds, windowFrame)
        
    }
    
}

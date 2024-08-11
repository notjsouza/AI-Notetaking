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
    
    func getWordFrames() -> [(String, CGRect)]? {
        
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
        
        let rect = CGRect(origin: position, size: size)
        
        let words = stringValue.split(separator: " ").map(String.init)
        let totalLength = CGFloat(stringValue.count)
        var wordFrames: [(String, CGRect)] = []
        
        var currentOffset: CGFloat = 0
        for word in words {
            
            let wordLength = CGFloat(word.count)
            let startX = rect.origin.x + (currentOffset / totalLength) * rect.width
            let wordWidth = (wordLength / totalLength) * rect.width
            
            let wordFrame = CGRect(x: startX, y: rect.origin.y, width: wordWidth, height: rect.height)
            wordFrames.append((word, wordFrame))
                        
            currentOffset += wordLength + 1
            
        }
        
        return wordFrames
        
    }
    
}

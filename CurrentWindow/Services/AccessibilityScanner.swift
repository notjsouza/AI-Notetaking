//
//  AccessibilityScanner.swift
//  CurrentWindow
//
//  Handles scanning windows for text content using macOS Accessibility API
//

import Foundation
import AppKit
import ApplicationServices

class AccessibilityScanner {
    
    // Browser detection - browsers don't expose web content
    private let browserBundleIds = [
        "com.google.Chrome",
        "com.apple.Safari",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "com.brave.Browser"
    ]
    
    /// Get the currently active window
    func getActiveWindow() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        
        guard result == .success, let app = focusedApp else {
            return nil
        }
        
        var focusedWindow: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        
        guard windowResult == .success, let window = focusedWindow else {
            return nil
        }
        
        return (window as! AXUIElement)
    }
    
    /// Collect all text elements from a window element
    func collectTextElements(from element: AXUIElement) -> [(element: AXUIElement, text: String, bounds: CGRect)] {
        var textElements: [(element: AXUIElement, text: String, bounds: CGRect)] = []
        
        // Get app name for browser detection
        let appName = getApplicationName(for: element)
        
        // Get window bounds for visibility filtering
        guard let windowBounds = getWindowBounds(element) else {
            return []
        }
        
        // Recursively collect all text elements
        collectTextElementsRecursive(element: element, windowBounds: windowBounds, results: &textElements)
        
        if textElements.isEmpty {
            print("No accessible text elements found in this window")
        }
        
        return textElements
    }
    
    // MARK: - Private Helper Methods
    
    private func collectTextElementsRecursive(
        element: AXUIElement,
        windowBounds: CGRect,
        results: inout [(element: AXUIElement, text: String, bounds: CGRect)]
    ) {
        // Get element role and value
        var roleValue: AnyObject?
        var value: AnyObject?
        
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        
        let role = roleValue as? String ?? ""
        
        // Skip URL/address bars in browsers
        if role == "AXTextField", let textValue = value as? String {
            if textValue.hasPrefix("http") || textValue.contains("://") {
                // Skip URL fields
                return
            }
        }
        
        // Check if this element contains text
        if let textValue = value as? String, !textValue.isEmpty, textValue.count > 2 {
            // Get element bounds
            if let bounds = getElementBounds(element) {
                // Calculate visibility ratio (30% threshold)
                let visibilityRatio = calculateVisibility(bounds: bounds, windowBounds: windowBounds)
                
                if visibilityRatio >= 0.30 {
                    results.append((element: element, text: textValue, bounds: bounds))
                }
            }
        }
        
        // Handle web content areas
        if role == "AXWebArea" {
            print("Found AXWebArea - diving into web content...")
        }
        
        // Recursively process children
        var childrenValue: AnyObject?
        let childrenResult = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenValue
        )
        
        if childrenResult == .success,
           let children = childrenValue as? [AXUIElement] {
            for child in children {
                collectTextElementsRecursive(element: child, windowBounds: windowBounds, results: &results)
            }
        }
    }
    
    private func getApplicationName(for element: AXUIElement) -> String {
        var nameValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &nameValue)
        return nameValue as? String ?? "Unknown"
    }
    
    private func getWindowBounds(_ element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        if let positionValue = positionValue {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }
        
        if let sizeValue = sizeValue {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        return CGRect(origin: position, size: size)
    }
    
    private func getElementBounds(_ element: AXUIElement) -> CGRect? {
        return getWindowBounds(element)
    }
    
    private func calculateVisibility(bounds: CGRect, windowBounds: CGRect) -> CGFloat {
        let intersection = bounds.intersection(windowBounds)
        let visibleArea = intersection.width * intersection.height
        let totalArea = bounds.width * bounds.height
        
        return totalArea > 0 ? visibleArea / totalArea : 0
    }
    
    /// Get text range bounds for a specific substring in an element
    func getTextBounds(for element: AXUIElement, text: String, characterRange: CFRange) -> CGRect? {
        var rangeValue: AnyObject?
        var mutableRange = characterRange
        let range = AXValueCreate(.cfRange, &mutableRange)
        
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            range as CFTypeRef,
            &rangeValue
        )
        
        guard result == .success, let rangeValue = rangeValue else {
            return nil
        }
        
        var bounds = CGRect.zero
        AXValueGetValue(rangeValue as! AXValue, .cgRect, &bounds)
        
        // Convert from Accessibility API coordinates (top-left origin) to NSPanel coordinates (bottom-left origin)
        guard let screen = NSScreen.main else { return nil }
        
        let adjustedY = screen.frame.height - bounds.origin.y - bounds.height
        let adjustedBounds = CGRect(
            x: bounds.origin.x - 1,
            y: adjustedY,
            width: bounds.width + 2,
            height: bounds.height
        )
        
        return adjustedBounds
    }
}

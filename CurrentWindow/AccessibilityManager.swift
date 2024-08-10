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
        //func getFocusedWindowElements() {
        
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
        
        /*
         // Attempts to assign focusedWindow the value of the focused application
         var focusedWindow: CFTypeRef?
         let windowResult = AXUIElementCopyAttributeValue(
         appElement,
         kAXMainWindowAttribute as CFString,
         &focusedWindow
         )
         */
        /*
         // Creates an AXUIElement object window with the value of focusedWindow if the process is successful, exits if unsuccessful
         guard windowResult == .success,
         let window = focusedWindow as! AXUIElement? else {
         print("Failed to get window")
         return
         }
         */
        
        /*
         // Creates the overlay for the application
         if let position = getPosition(element: window, attribute: kAXPositionAttribute),
         let size = getSize(element: window, attribute: kAXSizeAttribute) {
         if let appDelegate = self.appDelegate {
         WindowManager.shared.createOverlayWindow(at: position, with: size, with: appDelegate)
         }
         }
         */
        
        // Recursively runs through all the elements within the active application
        //getAllElements(element: window, level: 0)
        
    }
    /*
     private func getAllElements(element: AXUIElement, level: Int) {
     
     if let role = getAttributeInfo(element: element, attribute: kAXRoleAttribute) {
     if role == "AXTextArea" || role == "AXTextField" { //== "AXButton" {
     if let position = getPosition(element: element, attribute: kAXPositionAttribute) {
     if let size = getSize(element: element, attribute: kAXSizeAttribute) {
     if size.width > 0 && size.height > 0 {
     if let appDelegate = self.appDelegate {
     WindowManager.shared.createOverlayWindow(at: position, with: size, with: appDelegate)
     }
     }
     }
     }
     }
     }
     
     if let children = getChildren(element: element, attribute: kAXChildrenAttribute) {
     for child in children {
     getAllElements(element: child, level: level + 1)
     }
     }
     
     }
     
     /*
      Returns the attribute info (role, title, value) as a String
      */
     private func getAttributeInfo(element: AXUIElement, attribute: String) -> String? {
     
     var valuePtr: CFTypeRef?
     let res = AXUIElementCopyAttributeValue(element, attribute as CFString, &valuePtr)
     
     if res == .success, let value = valuePtr {
     return value as? String
     } else {
     return nil
     }
     
     }
     
     private func getPosition(element: AXUIElement, attribute: String) -> NSPoint? {
     
     var valuePtr: CFTypeRef?
     let res = AXUIElementCopyAttributeValue(element, attribute as CFString, &valuePtr)
     
     if res == .success, let value = valuePtr {
     var point = NSPoint()
     if AXValueGetValue(value as! AXValue, .cgPoint, &point) {
     return point
     }
     }
     
     return nil
     
     }
     
     private func getSize(element: AXUIElement, attribute: String) -> CGSize? {
     var valuePtr: CFTypeRef?
     let res = AXUIElementCopyAttributeValue(element, attribute as CFString, &valuePtr)
     
     if res == .success, let value = valuePtr {
     var size = CGSize()
     if AXValueGetValue(value as! AXValue, .cgSize, &size) {
     return size
     }
     }
     
     return nil
     
     }
     
     private func getChildren(element: AXUIElement, attribute: String) -> [AXUIElement]? {
     
     var valuePtr: CFTypeRef?
     let res = AXUIElementCopyAttributeValue(element, attribute as CFString, &valuePtr)
     
     if res == .success, let value = valuePtr {
     return value as? [AXUIElement]
     } else {
     return nil
     }
     
     }
     
     */
}

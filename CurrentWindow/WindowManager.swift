//
//  WindowManager.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/23/24.
//

import Cocoa
import SwiftUI

class WindowManager: ObservableObject {
    
    static let shared = WindowManager()
    private var wordOverlays: [NSWindow] = []
    
    //Check later
    private var borderWindow: NSWindow?
    
    func createBorderOverlay(for frame: CGRect) {
        
        guard let screen = NSScreen.main else { return }
        
        let adjustedY = screen.frame.height - frame.origin.y - frame.height
        let adjustedFrame = CGRect(
            x: frame.origin.x,
            y: adjustedY,
            width: frame.width,
            height: frame.height
        )
        
        if borderWindow == nil {
            borderWindow = NSWindow(
                contentRect: adjustedFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            borderWindow?.isOpaque = false
            borderWindow?.backgroundColor = .clear
            borderWindow?.level = .floating
            borderWindow?.hasShadow = false
            borderWindow?.ignoresMouseEvents = true
            
            let borderView = OverlayView(frame: NSRect(origin: .zero, size: frame.size))
            borderWindow?.contentView = borderView
            
        } else {
            
            borderWindow?.setFrame(adjustedFrame, display: true)
            
        }
        
        borderWindow?.orderFront(nil)
        
    }
    
    func createOverlay(text: String, element: AXUIElement) {
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        print(words)
        var curIndex = 0
        
        for word in words {
            
            if word.isEmpty {
                
                curIndex += 1
                continue
                
            }
            
            let range = NSRange(location: curIndex, length: word.count)
            curIndex += word.count + 1
            
            var cfRange = CFRangeMake(range.location, range.length)
            guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { continue }
            
            var boundsRef: CFTypeRef?
            let res = AXUIElementCopyParameterizedAttributeValue(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                rangeValue,
                &boundsRef
            )
            
            
            if res == .success, let boundsValue = boundsRef as! AXValue? {
                
                var bounds = CGRect.zero
                if AXValueGetValue(
                    boundsValue,
                    .cgRect,
                    &bounds
                ) {
                   
                    guard let screen = NSScreen.main else { return }
                    
                    let adjustedY = screen.frame.height - bounds.origin.y - bounds.height
                    let adjustedBounds = CGRect(
                        x: bounds.origin.x,
                        y: adjustedY,
                        width: bounds.width,
                        height: bounds.height
                    )
                    
                    createOverlayWindows(for: word, bounds: adjustedBounds)
                    
                } else {
                    
                    print("failed to get bounds for \(word)")
                    
                }
                
            }
            
        }
        
    }
    
    func createOverlayWindows(for word: String, bounds: CGRect) {
        
        let panel = NSPanel(
            contentRect: bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = NSColor.green.withAlphaComponent(0.3)//.clear
        panel.hasShadow = false
        panel.level = .floating
        panel.ignoresMouseEvents = false
        
        let contentView = NSHostingView(rootView: WordOverlayView(word: word, frame: bounds))
        panel.contentView = contentView
        
        panel.orderFront(nil)
        wordOverlays.append(panel)
        
    }
    
    func deleteBorderOverlay() {
        
        borderWindow?.close()
        
    }
    
    func deleteTextOverlay() {
        
        wordOverlays.forEach { $0.close() }
        wordOverlays.removeAll()
        
    }
    
    func deleteAll() {
        
        deleteBorderOverlay()
        deleteTextOverlay()
        
    }
     
}

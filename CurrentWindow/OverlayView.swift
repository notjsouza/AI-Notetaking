//
//  OverlayView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/20/24.
//

import Cocoa

class OverlayView: NSView {
    
    // For the element border
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        let borderColor = NSColor.green
        let borderWidth: CGFloat = 4.0
        
        let borderPath = NSBezierPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        borderColor.setStroke()
        borderPath.lineWidth = borderWidth
        borderPath.stroke()
        
    }
    
}

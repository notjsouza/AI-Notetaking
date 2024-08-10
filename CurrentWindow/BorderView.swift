//
//  BorderView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/24/24.
//

import Foundation
import Cocoa

class BorderView: NSView {
    
    var button: NSButton!
    let buttonSize: CGFloat = 30
    //var role: String?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    func setupButton() {
        button = NSButton(
            frame: NSRect(
                x: bounds.width - buttonSize,
                y: 0,
                width: buttonSize,
                height: buttonSize
            ))
        button.bezelStyle = .circular
        button.isBordered = false
        button.title = ""
        button.wantsLayer = true
        button.layer?.cornerRadius = buttonSize / 2
        button.layer?.backgroundColor = NSColor.green.cgColor
        addSubview(button)
    }
    
    override func layout() {
        super.layout()
        updateButtonPosition()
    }
    
    func updateButtonPosition() {
        let x = min(bounds.width - buttonSize, max(0, bounds.width - buttonSize))
        let y = max(0, min(bounds.height - buttonSize, bounds.height - buttonSize))
        button.frame.origin = CGPoint(x: x, y: y)
    }
}
    
    /*
    override func draw(_ dirtyRect: NSRect) {
        
     // For a green border around the focused element
        /*
        NSColor.green.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()
        */
        
        let circlePath = NSBezierPath(
            ovalIn: NSRect(
                x: bounds.width - circleSize,
                y: bounds.height - circleSize,
                width: circleSize,
                height: circleSize
            ))
        
        NSColor.green.setFill()
        circlePath.fill()
        
        /*
        
        // to print the role of the element in the overlay as well
        if let role = role {
            
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white,
                .backgroundColor: NSColor.black.withAlphaComponent(0.7),
                .font: NSFont.systemFont(ofSize: 12)
            ]
            
            let attributedString = NSAttributedString(string: role, attributes: attributes)
            attributedString.draw(at: NSPoint(x: 5, y: self.bounds.height - 20))
            
        }
         
         */
        
    }
     */

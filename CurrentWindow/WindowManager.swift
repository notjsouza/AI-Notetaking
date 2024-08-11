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
    
    func createOverlayWindow(wordFrames: [(String, CGRect)]) {
        
        wordOverlays.forEach { $0.close() }
        wordOverlays.removeAll()
        
        guard let screen = NSScreen.main else { return }
        
        for (word, frame) in wordFrames {
            
            let screenFrame = screen.convertToScreenCoordinates(frame)
            
            let menuBarHeight = screen.frame.height - screen.visibleFrame.height
            let adjustedFrame = CGRect(x: screenFrame.origin.x,
                                       y: screen.frame.height - screenFrame.origin.y - screenFrame.height - menuBarHeight,
                                       width: screenFrame.width,
                                       height: screenFrame.height
                                )
            
            let panel = NSPanel(
                contentRect: adjustedFrame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.isOpaque = false
            panel.backgroundColor = NSColor.red.withAlphaComponent(0.3)
            panel.hasShadow = false
            panel.level = .screenSaver
            panel.ignoresMouseEvents = false
            
            let contentView = NSHostingView(rootView: WordOverlayView(word: word))
            panel.contentView = contentView
            
            panel.orderFront(nil)
            wordOverlays.append(panel)
            
        }
    }
}

extension NSScreen {
    
    func convertToScreenCoordinates(_ rect: CGRect) -> CGRect {
        
        let screenHeight = self.frame.height
        return CGRect(x: rect.origin.x,
                      y: screenHeight - rect.origin.y - rect.height,
                      width: rect.width,
                      height: rect.height
                )
        
    }
    
}

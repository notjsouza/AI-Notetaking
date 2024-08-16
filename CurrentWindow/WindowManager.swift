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
    
    func createOverlayWindows(for textField: NSTextField, elementFrame: CGRect) {
        
        removeAllOverlays()
        
        let text = textField.stringValue
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        guard let screen = NSScreen.main else { return }
        
        var horizontalPadding: CGFloat = 5
        var verticalPadding: CGFloat = 2
        
        for (index, word) in words.enumerated() {
            
            if var frame = frameForWord(at: index, in: textField) {
                
                frame.origin.x += horizontalPadding
                frame.origin.y += verticalPadding
                
                let screenFrame = CGRect(
                    x: elementFrame.minX + frame.minX,
                    y: screen.frame.maxY - (elementFrame.minY + frame.minY + frame.height),
                    width: frame.width + 10,
                    height: frame.height + 4
                )
                
                print("Adjusted frame for '\(word)': \(screenFrame)")
                
                let panel = NSPanel(
                    contentRect: screenFrame,
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                
                panel.isOpaque = false
                panel.backgroundColor = NSColor.green.withAlphaComponent(0.3)//.clear
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
    
    private func frameForWord(at index: Int, in textField: NSTextField) -> NSRect? {
        
        let text = textField.stringValue
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard index < words.count else { return nil }
        
        let wordToFind = words[index]
        let precedingWords = words[0..<index].joined(separator: " ")
        let startIndex = text.index(text.startIndex, offsetBy: precedingWords.count + (index > 0 ? 1 : 0))
        let endIndex = text.index(startIndex, offsetBy: wordToFind.count)
        
        let range = NSRange(startIndex..<endIndex, in: text)
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: textField.bounds.size)
        let textStorage = NSTextStorage(string: text)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
    }
    
    func removeAllOverlays() {
        
        wordOverlays.forEach { $0.close() }
        wordOverlays.removeAll()
        
    }
    
    /*
    func createOverlayWindow(wordFrames: [(String, CGRect)]) {
        
        wordOverlays.forEach { $0.close() }
        wordOverlays.removeAll()
        
        guard let screen = NSScreen.main else { return }
        
        for (word, frame) in wordFrames {
            
            let screenFrame = screen.convertToScreenCoordinates(frame)
            
            let adjustedFrame = CGRect(x: screenFrame.origin.x,
                                       y: screenFrame.origin.y,
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
            panel.backgroundColor = NSColor.green.withAlphaComponent(0.1)
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
        
        return CGRect(x: rect.origin.x,
                      y: self.frame.height - rect.origin.y - rect.height,
                      width: rect.width,
                      height: rect.height
                )
        
    }
 
     */
     
}

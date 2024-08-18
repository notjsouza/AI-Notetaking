//
//  WindowManager.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/23/24.
//

import Cocoa
import SwiftUI
import Vision

class WindowManager: ObservableObject {
    
    static let shared = WindowManager()
    private var wordOverlays: [NSWindow] = []
    
    
    func captureScreenshot() -> CGImage? {
        
        if let screen = NSScreen.main {
            
            let cgImage = CGWindowListCreateImage(
                .zero,
                .optionOnScreenOnly,
                kCGNullWindowID,
                [.boundsIgnoreFraming]
            )
            return cgImage
            
        }
        
        return nil
        
    }
    
    func performTextRecognition(on image: CGImage, completion: @escaping ([VNRecognizedTextObservation]) -> Void) {
        
        let req = VNRecognizeTextRequest { req, error in
            
            guard let observations = req.results as? [VNRecognizedTextObservation] else {
                
                completion([])
                return
                
            }
            
            completion(observations)
            
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([req])
        
    }
    
    func createOverlayWindows() {
        
        guard let screenshot = captureScreenshot() else { return }
        
        performTextRecognition(on: screenshot) { observations in
            
            self.removeAllOverlays()
            
            for observation in observations {
                
                let boundingBox = observation.boundingBox
                let screenBounds = NSScreen.main!.frame
                
                let rect = CGRect(
                    x: boundingBox.minX * screenBounds.width,
                    y: ((boundingBox.maxY) * screenBounds.height) - 10,
                    width: boundingBox.width * screenBounds.width,
                    height: boundingBox.height * screenBounds.height
                )
                
                if let topCandidate = observation.topCandidates(1).first {
                    
                    self.createOverlayForWord(topCandidate.string, in: rect)
                    
                }
                
            }
            
        }
        
    }
        
    func createOverlayForWord(_ word: String, in rect: CGRect) {
                
        let panel = NSPanel(
            contentRect: rect,
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
    
    func removeAllOverlays() {
        
        wordOverlays.forEach { $0.close() }
        wordOverlays.removeAll()
        
    }
     
}

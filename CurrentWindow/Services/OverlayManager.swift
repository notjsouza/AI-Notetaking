//
//  OverlayManager.swift
//  CurrentWindow
//
//  Manages overlay window lifecycle (creation, display, deletion)
//

import SwiftUI
import ApplicationServices

class OverlayManager {
    
    private var overlayItems: [OverlayItem] = []
    private var suggestionWindow: NSPanel?
    
    var isSuggestionVisible: Bool = false
    
    // MARK: - Overlay Window Management
    
    /// Get all current overlay items
    func getAllOverlays() -> [OverlayItem] {
        return overlayItems
    }
    
    /// Set overlay items (used for differential updates)
    func setOverlays(_ items: [OverlayItem]) {
        overlayItems = items
    }
    
    /// Create an underline overlay for a word
    func createWordOverlay(word: String, bounds: CGRect) {
        // Check if overlay already exists
        if overlayItems.contains(where: { $0.wordBounds == bounds && $0.word == word}) {
            return
        }
        
        let panel = NSPanel(
            contentRect: bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.ignoresMouseEvents = true
        
        let contentView = NSHostingView(rootView: WordOverlayView(word: word, frame: bounds))
        panel.contentView = contentView
        
        panel.orderFront(nil)
        
        let overlayItem = OverlayItem(wordWindow: panel, wordBounds: bounds, word: word)
        overlayItems.append(overlayItem)
    }
    
    /// Create a suggestion popup window
    func createSuggestionWindow(word: String, bounds: CGRect, notes: [Note], onDismiss: @escaping () -> Void) {
        guard let overlayItemIndex = overlayItems.firstIndex(where: { $0.word == word && $0.wordBounds == bounds}) else { return }
        
        let adjustedBounds = CGRect(
            x: bounds.minX,
            y: bounds.maxY - 2,
            width: bounds.width,
            height: bounds.height
        )
        
        let panel = NSPanel(
            contentRect: adjustedBounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .white
        panel.hasShadow = false
        panel.level = .floating
        panel.ignoresMouseEvents = false
        
        let contentView = NSHostingView(rootView: SuggestionView(suggestions: notes, onDismiss: onDismiss))
        panel.contentView = contentView
        
        panel.orderFront(nil)
        
        overlayItems[overlayItemIndex].suggestionWindow = panel
        suggestionWindow = panel
        isSuggestionVisible = true
    }
    
    /// Delete a specific suggestion overlay
    func deleteSuggestionOverlay(for word: String, bounds: CGRect) {
        guard let index = overlayItems.firstIndex(where: { $0.word == word && $0.wordBounds == bounds}) else { return }
        
        overlayItems[index].suggestionWindow?.close()
        overlayItems[index].suggestionWindow = nil
        suggestionWindow = nil
        isSuggestionVisible = false
    }
    
    /// Delete all suggestion overlays
    func deleteAllSuggestionOverlays() {
        suggestionWindow?.close()
        suggestionWindow = nil
        isSuggestionVisible = false
        
        for index in overlayItems.indices {
            overlayItems[index].suggestionWindow?.close()
            overlayItems[index].suggestionWindow = nil
        }
    }
    
    /// Delete all overlays (words and suggestions)
    func deleteAllOverlays() {
        for overlayItem in overlayItems {
            overlayItem.wordWindow.close()
            overlayItem.suggestionWindow?.close()
        }
        
        overlayItems.removeAll()
        suggestionWindow = nil
        isSuggestionVisible = false
    }
    
    /// Remove specific overlays
    func removeOverlays(_ itemsToRemove: [OverlayItem]) {
        for item in itemsToRemove {
            item.wordWindow.close()
            item.suggestionWindow?.close()
            
            if let index = overlayItems.firstIndex(where: { $0.word == item.word && $0.wordBounds == item.wordBounds }) {
                overlayItems.remove(at: index)
            }
        }
    }
    
    /// Open a note in the Notes app
    func openNoteInApp(noteId: String) {
        print("Opening note with ID: \(noteId)")
        
        // Try the simple URL format first
        let urlString = "notes://showNote?identifier=\(noteId)"
        
        guard let url = URL(string: urlString) else {
            print("Failed to create Notes URL")
            return
        }
        
        // Use synchronous open - more reliable
        DispatchQueue.main.async {
            let success = NSWorkspace.shared.open(url)
            print(success ? "URL opened successfully" : "URL open failed")
        }
    }
}

// MARK: - CGRect Comparison Helper

extension CGRect {
    /// Check if two CGRects are effectively equal within a tolerance
    func isEffectivelyEqual(to other: CGRect, tolerance: CGFloat) -> Bool {
        return abs(self.origin.x - other.origin.x) <= tolerance &&
               abs(self.origin.y - other.origin.y) <= tolerance &&
               abs(self.width - other.width) <= tolerance &&
               abs(self.height - other.height) <= tolerance
    }
}

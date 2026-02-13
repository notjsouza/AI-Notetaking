//
//  OverlayController.swift
//  CurrentWindow
//
//  Main coordinator that orchestrates scanning, note searching, and overlay management
//

import SwiftUI
import Combine

class OverlayController: ObservableObject {
    
    static let shared = OverlayController()
    
    @Published var isWordHovered: Bool = false
    @Published var isSuggestionHovered: Bool = false
    var isSuggestionVisible: Bool { overlayManager.isSuggestionVisible }
    
    // Services
    private let scanner = AccessibilityScanner()
    private let overlayManager = OverlayManager()
    private let notesClient = NotesServiceClient()
    private let refreshCoordinator = RefreshCoordinator()
    
    // State
    private var wordSuggestions: [String: [Note]] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let deletionDelay: TimeInterval = 0.2
    
    private init() {
        setupRefreshCoordinator()
    }
    
    // MARK: - Setup
    
    private func setupStateManagement() {
        Publishers.CombineLatest($isWordHovered, $isSuggestionHovered)
            .debounce(for: .seconds(deletionDelay), scheduler: RunLoop.main)
            .sink { [weak self] wordHovered, suggestionHovered in
                if !wordHovered && !suggestionHovered {
                    self?.overlayManager.deleteAllSuggestionOverlays()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRefreshCoordinator() {
        refreshCoordinator.onRefreshNeeded = { [weak self] in
            self?.refreshOverlays()
        }
    }
    
    // MARK: - Public API
    
    func start() {
        Task { @MainActor in
            setupStateManagement()
            
            do {
                if let message = try await notesClient.initializeIndex() {
                    // Index initialized
                } else {
                    print("Index could not be initialized")
                }
            } catch {
                print("Error initializing index: \(error)")
            }
        }
    }
    
    func runApp() {
        guard let window = scanner.getActiveWindow() else { return }
        print("Retrieved app successfully")
        
        // Initial scan and overlay creation
        collectAndProcess()
        
        // Start periodic refresh
        refreshCoordinator.startPeriodicRefresh()
    }
    
    func triggerImmediateRefresh() {
        refreshCoordinator.triggerImmediateRefresh()
    }
    
    func deleteAll() {
        refreshCoordinator.stopPeriodicRefresh()
        overlayManager.deleteAllOverlays()
        wordSuggestions.removeAll()
    }
    
    func getActiveWindow() -> AXUIElement? {
        return scanner.getActiveWindow()
    }
    
    // MARK: - User Interactions
    
    func setWordHovered(word: String, hovering: Bool, frame: CGRect) {
        isWordHovered = hovering
        
        if hovering && !overlayManager.isSuggestionVisible {
            if let notes = wordSuggestions[word] {
                overlayManager.createSuggestionWindow(
                    word: word,
                    bounds: frame,
                    notes: notes,
                    onDismiss: { [weak self] in
                        self?.overlayManager.deleteSuggestionOverlay(for: word, bounds: frame)
                    }
                )
            }
        }
    }
    
    func setSuggestionHovered(hovering: Bool) {
        isSuggestionHovered = hovering
    }
    
    func setNoteSelected(note: Note) {
        print("🔵 Note selected: \(note.title)")
        overlayManager.openNoteInApp(noteId: note.id)
        overlayManager.deleteAllSuggestionOverlays()
    }
    
    // MARK: - Core Logic
    
    private func collectAndProcess() {
        guard let window = scanner.getActiveWindow() else { return }
        
        // Delete existing overlays before creating new ones
        overlayManager.deleteAllOverlays()
        
        let textElements = scanner.collectTextElements(from: window)
        
        if textElements.isEmpty {
            return
        }
        
        print("Processing \(textElements.count) text elements...")
        
        // Combine all text
        let allText = textElements.map { $0.text }.joined(separator: " ")
        
        Task {
            do {
                // Filter text server-side
                let filteredWords = try await notesClient.filterText(allText)
                print("Filtered to \(filteredWords.count) words: \(filteredWords.prefix(10))")
                
                // Batch search notes
                let results = try await notesClient.searchNotesBatch(words: filteredWords)
                wordSuggestions = results
                print("Found suggestions for \(wordSuggestions.count) words")
                
                // Create overlays
                await createOverlaysForMatchingWords(textElements: textElements)
                
            } catch {
                print("Error processing text: \(error)")
            }
        }
    }
    
    @MainActor
    private func createOverlaysForMatchingWords(textElements: [(element: AXUIElement, text: String, bounds: CGRect)]) {
        for (element, text, _) in textElements {
            let words = text.split(separator: " ").map(String.init)
            var characterIndex = 0
            
            for word in words {
                if wordSuggestions.keys.contains(word) {
                    let range = CFRange(location: characterIndex, length: word.count)
                    
                    if let bounds = scanner.getTextBounds(for: element, text: text, characterRange: range) {
                        overlayManager.createWordOverlay(word: word, bounds: bounds)
                    }
                }
                
                characterIndex += word.count + 1  // +1 for space
            }
        }
    }
    
    private func refreshOverlays() {
        guard let window = scanner.getActiveWindow() else {
            refreshCoordinator.pauseRefresh()
            return
        }
        
        // Get current window position
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        if let positionValue = positionValue {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }
        if let sizeValue = sizeValue {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        let currentPosition = CGRect(origin: position, size: size)
        
        // Check if position changed
        refreshCoordinator.checkPositionAndRefresh(currentPosition: currentPosition) {
            collectAndProcess()
        }
    }
}

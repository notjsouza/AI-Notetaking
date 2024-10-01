//
//  OverlayController.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/25/24.
//



/*
 
 Only issue I wasn't able to solve: 
 
 The overlay doesn't properly update on changes. Two things that could fix this are either
 
    1. Updating the contents on a timer
    2. Checking the observers in the AppDelegate to make sure they're calling updates properly
 
 I left the border functions commented out, I used those to find the bounding boxes for elements
 and make sure the program was registering applications properly.
  
 */

import SwiftUI
import Combine
import Alamofire

class OverlayController: ObservableObject {
    
    static let shared = OverlayController()
    
    @Published var isWordHovered: Bool = false
    @Published var isSuggestionHovered: Bool = false
    @Published var isSuggestionVisible: Bool = false
    
    @Published private(set) var noteWindows: [NoteWindow] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let deletionDelay: TimeInterval = 0.2
    
    private var overlayItems: [OverlayItem] = []
    private var word_suggestions: [String: [Note]] = [:]
    
    private var panelDictionary: [NoteWindow: NSPanel] = [:]
    
    // vv For Debugging vv //
    //private var borderWindows: [NSWindow] = []
    
    // ------------------------ INITIALIZERS --------------------------------
    
    // Using this function to create a small delay before deleting the suggestion window
    private func setupStateManagement() {
        
        Publishers.CombineLatest($isWordHovered, $isSuggestionHovered)
            .debounce(for: .seconds(deletionDelay), scheduler: RunLoop.main)
            .sink { [weak self] wordHovered, suggestionHovered in
                if !wordHovered && !suggestionHovered {
                    self?.deleteSuggestionOverlay()
                }
            }
            .store(in: &cancellables)
    }
    
    // Creates the delay, then calls the Flask server to initialize the index
    func start() {
        
        Task { @MainActor in
            
            setupStateManagement()
            
            do {
                if let message = try await initializeIndex() {
                    print(message)
                } else {
                    print("Index could not be initialized")
                }
            } catch {
                print("Error initializing index: \(error)")
            }
        }
    }
    
    // Recurring call to find the active application, then retrieves all the elements on the page
    func runApp() {
        
        guard let app = getActiveWindow() else { return }
        print("Retrieved app successfully")
        
        getAllElements(element: app)
    }
    
    // ------------------------ ELEMENT PROPERTIES ------------------------
    
    // Finds the active application, then returns the window property as a AXUIElement
    func getActiveWindow() -> AXUIElement? {
        
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
              let window = windowRef as! AXUIElement? else { return nil }
        
        return window
    }
    
    // Finds the active window, then finds all the child elements of the window
    private func getAllElements(element: AXUIElement) {
        
        let windowFrame = getWindowFrame(element: element)
        guard let windowFrame = windowFrame else { return }
        
        findChildren(element: element, frame: windowFrame)
    }
    
    // Finds the bounds of the window, returns as an optional CGRect
    private func getWindowFrame(element: AXUIElement) -> CGRect? {
        
        var roleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String, role == "AXWindow" else { return nil }
        
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let positionValue = positionRef as! AXValue?,
              let sizeValue = sizeRef as! AXValue? else { return nil }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionValue, .cgPoint, &position)
        AXValueGetValue(sizeValue, .cgSize, &size)
        
        let windowFrame = CGRect(origin: position, size: size)
        return windowFrame
    }
    
    // Recursive function to go thorugh all the elements, creates an overlay window if the role of the element is a textfield and
    // if the element falls within the visible bounds
    private func findChildren(element: AXUIElement, frame: CGRect) {
        
        var roleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String else { return }
        
        if role.contains("Text") {
            
            var positionRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
                  AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
                  let positionValue = positionRef as! AXValue?,
                  let sizeValue = sizeRef as! AXValue? else { return }
            
            var position = CGPoint.zero
            var size = CGSize.zero
            
            AXValueGetValue(positionValue, .cgPoint, &position)
            AXValueGetValue(sizeValue, .cgSize, &size)
            
            let elementBounds = CGRect(origin: position, size: size)
            
            if frame.intersects(elementBounds) {
                createOverlay(element: element)
                
                // vv For debugging, using this to make sure every element in a window is bounded vv //
                
                //createBorderOverlay(for: elementBounds)
                
                // ---------------------------------------------------------------------------------
                
            }
        }
        
        var childRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childRef) == .success,
              let children = childRef as? [AXUIElement] else { return }
        
        for child in children {
            findChildren(element: child, frame: frame)
        }
    }
    
    // ------------------------ SETTERS ---------------------------------
    
    func setWordHovered(word: String, hovering: Bool, frame: CGRect) {
        isWordHovered = hovering
        
        if hovering && !isSuggestionVisible {
            createSuggestionWindow(word: word, bounds: frame)
            print("Word Hovered \(word)")
        }
    }
    
    func setSuggestionHovered(hovering: Bool) {
        isSuggestionHovered = hovering
    }
    
    func setNoteSelected(note: Note) {
        
        createNoteWindow(note: note)
        deleteSuggestionOverlay()
        
    }
    
    // ------------------------ OVERLAY CREATORS ------------------------
    
    // Deletes any existing overlay items before creating new ones
    // Sends text contents to be cleaned, loops through each of them to see if any return notes
    // Any words that return a note are used to create an overlay item
    private func createOverlay(element: AXUIElement) {
        
        Task { @MainActor in
            
            var filteredWords: [String] = []
            
            deleteTextOverlay()
            
            var valueRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef) == .success,
                  let value = valueRef as? String else { return }
            
            do {
                filteredWords = try await checkTextWithServer(words: value)
            } catch {
                print("Failed to clean text")
                return
            }
            
            for word in filteredWords {
                
                let suggestions = try await self.searchNotes(for: word)
                
                if !suggestions.isEmpty {
                    word_suggestions[word] = suggestions
                }
            }
            
            let words = value.components(separatedBy: .whitespacesAndNewlines)
            var curIndex = 0
            
            for word in words {
                
                if word.isEmpty {
                    curIndex += 1
                    continue
                }
                
                if let suggestions = word_suggestions[word] {
                    
                    let range = NSRange(location: curIndex, length: word.count)
                    curIndex += word.count + 1
                    
                    var cfRange = CFRangeMake(range.location, range.length)
                    guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return }
                    
                    var boundsRef: CFTypeRef?
                    let res = AXUIElementCopyParameterizedAttributeValue(
                        element,
                        kAXBoundsForRangeParameterizedAttribute as CFString,
                        rangeValue,
                        &boundsRef
                    )
                    
                    if res == .success, let boundsValue = boundsRef as! AXValue? {
                        var bounds = CGRect.zero
                        if AXValueGetValue(boundsValue, .cgRect, &bounds) {
                            
                            guard let screen = NSScreen.main else { return }
                            
                            let adjustedY = screen.frame.height - bounds.origin.y - bounds.height
                            let adjustedBounds = CGRect(
                                x: bounds.origin.x - 1,
                                y: adjustedY,
                                width: bounds.width + 2,
                                height: bounds.height
                            )
                            
                            createOverlayWindows(for: word, bounds: adjustedBounds)
                            print("Overlay created for word \(word) at \(adjustedBounds)")
                            
                        } else {
                            print("Fauled to get bounds for \(word)")
                        }
                    }
                }
            }
        }
    }
    
    // Creates an underline/highlight effect around a relevant word
    private func createOverlayWindows(for word: String, bounds: CGRect) {
        
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
        self.overlayItems.append(overlayItem)
    }
    
    private func createSuggestionWindow(word: String, bounds: CGRect) {
        
        guard let overlayItemIndex = overlayItems.firstIndex(where: { $0.word == word && $0.wordBounds == bounds}) else { return }
        
        guard let notes = word_suggestions[word] else { return }
        
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
        
        let contentView = NSHostingView(rootView: SuggestionView(suggestions: notes, onDismiss: { [weak self] in
            self?.deleteSuggestionOverlay(for: word, bounds: bounds)
        }))
        panel.contentView = contentView
        
        panel.orderFront(nil)
        
        overlayItems[overlayItemIndex].suggestionWindow = panel
        isSuggestionVisible = true
    }
    
    private func createNoteWindow(note: Note) {
        guard let screen = NSScreen.main else { return }
        
        let noteBounds = CGRect(
            x: 100,
            y: screen.frame.height / 2,
            width: 250,
            height: 200
        )
        
        let panel = NSPanel(
            contentRect: noteBounds,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        
        let noteWindow = NoteWindow(note: note, position: panel.frame.origin, bounds: panel.frame)
        
        let contentView = NSHostingView(rootView: NoteView(noteWindow: noteWindow, onDismiss: { [weak self] noteWindow in
            self?.deleteNoteOverlay(noteWindow: noteWindow)
        }))
        panel.contentView = contentView
        
        panel.setContentSize(contentView.fittingSize)
        
        panel.orderFront(nil)
        noteWindows.append(noteWindow)
        panelDictionary[noteWindow] = panel
    }
    
    // ------------------------ FETCH FUNCTIONS --------------------------
    
    // POST request to initialize the index in the Flask server
    private func initializeIndex() async throws -> String? {
        
        guard let url = URL(string: "http://127.0.0.1:5000/initialize") else { return nil}
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: req)
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let message = json["message"] as? String { return message }
        
        return nil
    }
    
    // POST request to send the text contents to the Flask server, filters out all duplicates and stopwords
    private func checkTextWithServer(words: String) async throws -> [String] {
        
        let parameters: [String: String] = ["text": words]
        let url = "http://127.0.0.1:5000/filter_text"
        
        let res = try await AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .serializingDecodable([String].self)
            .value
        return res
    }
    
    // POST request to return the notes relevant to the given keyword
    private func searchNotes(for word: String) async throws -> [Note] {
        
        guard let url = URL(string: "http://127.0.0.1:5000/search") else {
            print("Failed to get url")
            return []
        }
        
        print("Successfully fetched URL")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["query": word]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: req)
        
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let relatedNotes = jsonResult?["related_notes"] as? [[String: String]] else {
            print("Failed to extract related_notes from JSON")
            return []
        }
        
        let notes = relatedNotes.map { noteData in
            Note(id: UUID().uuidString,
                 title: noteData["title"] ?? "",
                 content: noteData["content"] ?? "")
        }
        
        return notes
    }
    
    // ------------------------ CLEANUP / DELETERS ------------------------
    
    func deleteAll() {
        
        deleteTextOverlay()
        deleteSuggestionOverlay()
    }
    
    private func deleteTextOverlay() {
        
        for item in overlayItems {
            item.wordWindow.close()
            item.suggestionWindow?.close()
        }
        overlayItems.removeAll()
        isSuggestionVisible = false
    }
    
    private func deleteSuggestionOverlay() {
        
        for index in overlayItems.indices {
            overlayItems[index].suggestionWindow?.close()
            overlayItems[index].suggestionWindow = nil
        }
        isSuggestionVisible = false
    }
    
    private func deleteSuggestionOverlay(for word: String, bounds: CGRect) {
        
        if let index = overlayItems.firstIndex(where: { $0.word == word && $0.wordBounds == bounds}) {
            overlayItems[index].suggestionWindow?.close()
            overlayItems[index].suggestionWindow = nil
        }
        isSuggestionVisible = overlayItems.contains { $0.suggestionWindow != nil }
    }
    
    private func deleteNoteOverlay(noteWindow: NoteWindow) {
        if let index = noteWindows.firstIndex(where: { $0.id == noteWindow.id }) {
            noteWindows.remove(at: index)
            panelDictionary[noteWindow]?.close()
            panelDictionary[noteWindow] = nil
        }
    }
}

/*
// --------------------------- V FOR DEBUGGING V ---------------------------
// ------------------------------------------------------------------------
 
    func clearBorders() {
     
        print("Clearing drawn borders...")
        for window in borderWindows {
            window.close()
        }
        borderWindows.removeAll()
    }

    private func createBorderOverlay(for frame: CGRect) {
            
        guard let screen = NSScreen.main else { return }
            
        let adjustedY = screen.frame.height - frame.origin.y - frame.height
        let adjustedFrame = CGRect(
            x: frame.origin.x,
            y: adjustedY,
            width: frame.width,
            height: frame.height
        )
            
        
        let borderWindow = NSWindow(
            contentRect: adjustedFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
                
        borderWindow.isOpaque = false
        borderWindow.backgroundColor = .clear
        borderWindow.level = .floating
        borderWindow.hasShadow = false
        borderWindow.ignoresMouseEvents = true
            
        let border = BorderManager(frame: NSRect(origin: .zero, size: frame.size))
        borderWindow.contentView = border
        
        borderWindow.orderFront(nil)
        borderWindows.append(borderWindow)
    }
}
 
 class BorderManager: NSView {
 
 override func draw(_ dirtyRect: NSRect) {
 
 super.draw(dirtyRect)
 
 let borderColor = NSColor.green
 let borderWidth: CGFloat = 2.0
 
 let borderPath = NSBezierPath(rect: bounds)
 borderColor.setStroke()
 borderPath.lineWidth = borderWidth
 borderPath.stroke()
 
 }
 }
 */

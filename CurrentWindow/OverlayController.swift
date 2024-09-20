//
//  OverlayController.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/25/24.
//

import SwiftUI
import Combine
import Alamofire

class OverlayController: ObservableObject {
    
    static let shared = OverlayController()
    
    @Published var isWordHovered: Bool = false
    @Published var isSuggestionHovered: Bool = false
    @Published var isSuggestionVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let deletionDelay: TimeInterval = 0.2
    
    var overlayItems: [OverlayItem] = []
    
    //Fix later if time
    var notes: [Note] = []
    
    @Published private(set) var noteWindows: [NoteWindow] = []
    private var panelDictionary: [NoteWindow: NSPanel] = [:]
    
    //DELETE LATER
    private var borderWindow: NSWindow?
        
    // ------------------------ INITIALIZERS --------------------------------
        
    init() {
        
        setupStateManagement()
        /*
        initializeIndex { message in
            if let message = message {
                print(message)
            } else {
                print("Index could not be initialized")
            }
        }
         */
    }
    
    func test_start() {
        initializeIndex { message in
            if let message = message {
                print(message)
            } else {
                print("Index could not be initialized")
            }
        }
    }
    
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
    
    func runApp() {
        
        guard let (curValue, curElement, curBounds) = getTextFieldData() else { return }
        
        createOverlay(text: curValue, element: curElement)
        createBorderOverlay(for: curBounds)
         
    }
    
    // ------------------------ ELEMENT PROPERTIES ------------------------
    
    func getFocusedApp() -> (AXUIElement, AXUIElement) /* -> (window, element) */ {
        
        guard let app = NSWorkspace.shared.frontmostApplication else { return (AXUIElementCreateSystemWide(), AXUIElementCreateSystemWide()) }
        
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        let elementError = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard elementError == .success, let element = focusedElement as! AXUIElement? else { return (appElement, appElement) }
        
        var windowElement: CFTypeRef?
        let windowError = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowAttribute as CFString,
            &windowElement
        )
        guard windowError == .success, let window = windowElement as! AXUIElement? else { return (appElement, element) }
        
        return (window, element)
    }
    
    private func getTextFieldData() -> (String, AXUIElement, CGRect)? {
                
        let (_, element) = getFocusedApp()
        
        var valueRef: CFTypeRef?
        let valueRes = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueRef
        )
        guard valueRes == .success, let value = valueRef as? String else { return nil }
        
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
                
        let elementBounds = CGRect(origin: position, size: size)
        
        return (value, element, elementBounds)
        
    }
    
    // ------------------------ SETTERS ---------------------------------
    
    func setWordHovered(word: String, hovering: Bool, frame: CGRect) {
        isWordHovered = hovering
                
        if hovering && !isSuggestionVisible {
            createSuggestionWindow(word: word, bounds: frame)
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
    
    private func createOverlay(text: String, element: AXUIElement) {
        
        deleteTextOverlay()
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        var curIndex = 0

        checkWordsWithServer(words: words) { [weak self] matchingNotes in
            guard let matchingNotes = matchingNotes else {
                print("No matching notes found")
                return
            }
            DispatchQueue.main.async { [weak self] in
                for word in words {
                    if word.isEmpty {
                        curIndex += 1
                        continue
                    }
                      
                    if let notesForWord = matchingNotes[word.lowercased()] {
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
                                    x: bounds.origin.x - 1,
                                    y: adjustedY,
                                    width: bounds.width + 2,
                                    height: bounds.height
                                )
                                self?.createOverlayWindows(for: word, bounds: adjustedBounds)
                                print("Overlay created for word \(word) at \(adjustedBounds)")
                            } else {
                                print("Fauled to get bounds for \(word)")
                            }
                        }
                    }  else {
                        print("No matching notes for word: \(word)")
                    }
                }
            }
        }
    }
    
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
        
        guard let overlayItemIndex = overlayItems.firstIndex(where: { $0.word == word && $0.wordBounds == bounds}) else {
            return
        }
        
        fetchNote(for: word, completionHandler: { [weak self] notes in
            
            DispatchQueue.main.async { [weak self] in
                
                //DEBUGGING
                if let notes = notes, !notes.isEmpty {
                    print("Note recieved \(notes.map { $0.title })")
                                        
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
                    
                    let contentView = NSHostingView(rootView: SuggestionView(suggestions: notes, onDismiss: {
                        self?.deleteSuggestionOverlay(for: word, bounds: bounds)
                    }))
                    panel.contentView = contentView
                    
                    panel.orderFront(nil)
                    
                    self?.overlayItems[overlayItemIndex].suggestionWindow = panel
                    self?.isSuggestionVisible = true
                } else {
                    print("Filed to retrieve note")
                }
            }
        })
    }
    
    func createNoteWindow(note: Note) {
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
    
    func updateNoteWindow(_ noteWindow: NoteWindow, newPosition: CGPoint? = nil, newBounds: CGRect? = nil) {
        if let index = noteWindows.firstIndex(where: { $0.id == noteWindow.id }) {
            var updatedNoteWindow = noteWindow
                
            if let newPosition = newPosition {
                updatedNoteWindow.position = newPosition
            }
                
            if let newBounds = newBounds {
                updatedNoteWindow.bounds = newBounds
            }
                
            noteWindows[index] = updatedNoteWindow
                
            if let panel = panelDictionary[noteWindow] {
                panel.setFrameOrigin(updatedNoteWindow.position)
                panel.setContentSize(updatedNoteWindow.bounds.size)
            }
        }
    }
    
    // ------------------------ FETCH FUNCTIONS --------------------------
    
    private func initializeIndex(completionHandler: @escaping (String?) -> Void) {
        guard let url = URL(string: "http://127.0.0.1:5000/initialize") else {
            completionHandler(nil)
            return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                completionHandler(nil)
                return
            }
            
            guard let data = data else {
                completionHandler(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = json["message"] as? String {
                    completionHandler(message)
                } else {
                    completionHandler(nil)
                }
            } catch {
                completionHandler(nil)
            }
        }.resume()
    }
    
    private func fetchNote(for word: String, completionHandler: @escaping ([Note]?) -> Void) {
        guard let url = URL(string: "http://127.0.0.1:5000/get_note") else {
            print("Failed to get url")
            completionHandler(nil)
            return
        }
        
        print("Successfully fetched URL")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["word": word]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completionHandler(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completionHandler(nil)
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString)")
            }
            
            do {
                let notes = try JSONDecoder().decode([Note].self, from: data)
                completionHandler(notes)
            } catch {
                print("Failed to decode response: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }.resume()
    }
    
    func fetchAllNotes(completionHandler: @escaping ([Note]) -> Void) {
        
        print("Fetching all notes...")
        
        guard let url = URL(string: "http://127.0.0.1:5000/api/notes") else {
            print("Failed to get url")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Note].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching notes: \(error.localizedDescription)")
                }
            }, receiveValue: { notes in
                completionHandler(notes)
            })
            .store(in: &cancellables)
    }
    
    private func checkWordsWithServer(words: [String], completion: @escaping ([String: [Note]]?) -> Void) {
        
        let cleanedWords = words.map { word in
            word.lowercased()
                .components(separatedBy: CharacterSet.punctuationCharacters)
                .joined()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let parameters: [String: [String]] = ["words": cleanedWords]
        let url = "http://127.0.0.1:5000/check_word"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let result = try JSONDecoder().decode([String: [Note]].self, from: data)
                        completion(result)
                    } catch {
                        print("Failed to decode JSON: \(error)")
                        completion(nil)
                    }
                case .failure(let error):
                    print("Error checking words: \(error)")
                    completion(nil)
                }
            }
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

    
// -----V FOR DEBUGGING - DELETE LATER V ----------------------------------
// ------------------------------------------------------------------------
    
    private func createBorderOverlay(for frame: CGRect) {
            
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
            
            let border = BorderManager(frame: NSRect(origin: .zero, size: frame.size))
            borderWindow?.contentView = border
        } else {
            borderWindow?.setFrame(adjustedFrame, display: true)
        }
        borderWindow?.orderFront(nil)
    }
}

class BorderManager: NSView {
    
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

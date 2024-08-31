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
        
    private var activeTextField: String = ""
    private var bounds: CGRect?
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let deletionDelay: TimeInterval = 0.2
    
    private var wordOverlays: [(NSWindow, CGRect)] = []
    private var suggestionOverlay: NSWindow?
    private var noteOverlay: [NSWindow] = []
    
    private var hoveredWordFrame: CGRect?
    private var suggestionWindowBounds: CGRect?
    
    //DELETE LATER
    private var borderWindow: NSWindow?
        
    // ------------------------ TIMERS --------------------------------
        
    init() {
        setupStateManagement()
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
    
    func startTimer() {
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] timer in
            self?.checkCurrentTextFieldValue()
        }
    }
    
    // ------------------------ SETTERS ---------------------------------
    
    func setWordHovered(word: String, hovering: Bool, frame: CGRect) {
        isWordHovered = hovering
        print("word: \(isWordHovered)")
        
        if hovering && !isSuggestionVisible {
            createSuggestionWindow(word: word, bounds: frame)
        }
    }
        
    func setSuggestionHovered(hovering: Bool) {
        isSuggestionHovered = hovering
        print("suggestion: \(isSuggestionHovered)")
    }
    
    func setNoteSelected(note: Note) {
        
        createNoteWindow(note: note)
        
    }
    
    // ------------------------ TEXT FUNCTIONS ------------------------
    
    private func checkCurrentTextFieldValue() {
        
        guard let (curValue, curElement, curBounds) = getTextFieldData() else { return }
        
        if curValue != activeTextField {
                
            activeTextField = curValue
            print(activeTextField)
            
            deleteTextOverlay()
            createOverlay(text: activeTextField, element: curElement)

        }
        
        if curBounds != bounds {
            
            // ADJUST THIS FOR THE PORTION THAT IS IN VIEW
            // in the case where there's a scrollbar it's typically going offscreen
            
            bounds = curBounds
            //print(curBounds)

            createBorderOverlay(for: curBounds)
    
        }
                
    }
    
    private func getTextFieldData() -> (String, AXUIElement, CGRect)? {
        
        // Defines app as the focused application
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        // Grabs the PID of app, and creates an accessibility object using the pid of the focused application
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedElement: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard res == .success, let element = focusedElement as! AXUIElement? else { return nil }
        
        var valueRef: CFTypeRef?
        let valueRes = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueRef
        )
        guard valueRes == .success, let value = valueRef as? String else { return nil }
        
        
        // CHECK HERE IF ANY PROBLEMS
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
    
    // ------------------------ OVERLAY CREATORS ------------------------
    
    private func createOverlay(text: String, element: AXUIElement) {
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
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
                    
                    let checkedString = word.filter { $0.isLetter || $0.isNumber }
                    
                    checkWordWithServer(word: checkedString) { [weak self] isRelevant in
                        if isRelevant {
                            print("Relevant word identified: \(word)")
                            self?.createOverlayWindows(for: word, bounds: adjustedBounds)
                        }
                    }
                } else {
                    print("failed to get bounds for \(word)")
                }
            }
        }
    }
    
    private func createOverlayWindows(for word: String, bounds: CGRect) {
        
        print("overlay drawing...")
        
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
        
        wordOverlays.append((panel, bounds))
        print("Word panel drawn")
        
    }
    
    private func createSuggestionWindow(word: String, bounds: CGRect) {
        
        if suggestionOverlay != nil {
            deleteSuggestionOverlay()
        }
    
        var suggestions: [Note] = []
        
        fetchNote(for: word, completionHandler: { [weak self] note in
            
            guard let self = self else { return }
            
            if let note = note {
                print("Note recieved \(note.title)")
                suggestions.append(note)
            } else {
                print("Filed to retrieve note")
            }
            
            DispatchQueue.main.async {
                
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
                
                let contentView = NSHostingView(rootView: SuggestionView(suggestions: suggestions, onDismiss: {
                    self.deleteSuggestionOverlay()
                }))
                panel.contentView = contentView
                
                panel.orderFront(nil)
                self.suggestionOverlay = panel
                self.isSuggestionVisible = true
                
            }
            
        })
        
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
        
        let contentView = NSHostingView(rootView: NoteView(note: note, onDismiss: {
            self.deleteNoteOverlay()
        }))
        panel.contentView = contentView
        
        panel.setContentSize(contentView.fittingSize)
        
        panel.orderFront(nil)
        noteOverlay.append(panel)
        
    }
    
    // ------------------------ FETCH FUNCTIONS --------------------------
    
    private func fetchNote(for word: String, completionHandler: @escaping (Note?) -> Void) {
        
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
                print("No data recieved")
                completionHandler(nil)
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode(Note.self, from: data) {
                completionHandler(decodedResponse)
            } else {
                print("Failed to decode response")
                completionHandler(nil)
            }
        }.resume()
                
    }
    
    private func checkWordWithServer(word: String, completion: @escaping (Bool) -> Void) {
        
        let parameters: [String: String] = ["word": word]
        let url = "http://127.0.0.1:5000/check_word"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let isRelevant = json["is_relevant"] as? Bool {
                        completion(isRelevant)
                    } else {
                        completion(false)
                    }
                case .failure(let error):
                    print("Error checking word: \(error)")
                    completion(false)
                }
            }
    }
    
    // ------------------------ NOTE RETRIEVAL --------------------------
    
    private func checkToDeleteSuggestionOverlay() {
                
        print("isWordHovered: \(isWordHovered), isSuggestionHovered: \(isSuggestionHovered)")
        if !isWordHovered && !isSuggestionHovered {
            deleteSuggestionOverlay()
            print("deleting window")
        }
    }
    
    // ------------------------ CLEANUP / DELETERS ------------------------
    
    func deleteAll() {
        
        deleteBorderOverlay()
        deleteTextOverlay()
        deleteSuggestionOverlay()
        deleteNoteOverlay()
    }
    
    func stopTimer() {
        
        timer?.invalidate()
        
    }
    
    private func deleteBorderOverlay() {
        
        borderWindow?.close()
        
    }
    
    private func deleteTextOverlay() {
        
        wordOverlays.forEach { $0.0.close() }
        wordOverlays.removeAll()
        
    }
    
    private func deleteSuggestionOverlay() {
        
        suggestionOverlay?.orderOut(nil)
        suggestionOverlay = nil
        isSuggestionVisible = false
        
    }
    
    private func deleteNoteOverlay() {
        
        noteOverlay.forEach { $0.close() }
        noteOverlay.removeAll()
        
    }
    
// -----V FOR DEBUGGING - DELETE LATER V ----------------------------------
    
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

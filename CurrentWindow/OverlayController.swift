//
//  OverlayController.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/25/24.
//

import SwiftUI

public class OverlayController: ObservableObject {
    
    private var activeTextField: String = ""
    private var bounds: CGRect?
    
    private var timer: Timer?
    
    //OverlayModel
    private var notes: [Note] = []
    
    //WindowManager
    private var wordOverlays: [(NSWindow, CGRect)] = []
    private var suggestionOverlay: NSWindow?
    
    //Check later
    private var borderWindow: NSWindow?
    
    private var hoveredWordFrame: CGRect?
    private var suggestionWindowBounds: CGRect?
    
    @Published var isWordHovered: Bool = false
    @Published var isSuggestionHovered: Bool = false
        
    // ------------------------ TIMERS --------------------------------

    func startTimer() {
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] timer in
        
            self?.checkCurrentTextFieldValue()
            
        }
        
    }
    
    // ------------------------ TEXT FUNCTIONS ------------------------
    
    func checkCurrentTextFieldValue() {
        
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
    
    func getTextFieldData() -> (String, AXUIElement, CGRect)? {
        
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
    
    func createOverlay(text: String, element: AXUIElement) {
        
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
                //print("\(boundsValue): \(word)")
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
                    
                    //print("\(adjustedBounds): \(word)")
                    createOverlayWindows(for: word, bounds: adjustedBounds)
                    
                } else {
                    
                    print("failed to get bounds for \(word)")
                    
                }
                
            }
            
        }
        
    }
    
    func createOverlayWindows(for word: String, bounds: CGRect) {
        
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
        
    }
    
    func createSuggestionWindow(word: String, bounds: CGRect) {
        
        fetchNote(for: word)
        let suggestions: [Note] = notes
        print(suggestions)
        
        let adjustedBounds = CGRect(
            x: bounds.minX,
            y: bounds.maxY,
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
        
        let contentView = NSHostingView(rootView: SuggestionView(suggestions: suggestions, onDismiss: { [weak self] in
            self?.deleteSuggestionOverlay()
            self?.notes.removeAll()
        }))
        panel.contentView = contentView
        
        panel.orderFront(nil)
        suggestionOverlay = panel
        
    }
    
    // ------------------------ NOTE RETRIEVAL --------------------------
    
    func fetchNote(for word: String) {
        
        guard let url = URL(string: "http://127.0.0.1:5000/get_note") else {
            print("Failed to get url")
            return
        }
        
        print("Successfully fetched URL")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["word": word]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data recieved")
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode(Note.self, from: data) {
                
                self?.notes.append(Note(title: decodedResponse.title, content: decodedResponse.content))
                return
            } else {
                print("Failed to decode response")
                return
            }
        }.resume()
                
    }
    
    private func processNote() {
        
        
        
    }
    
    // ------------------------ SETTERS ---------------------------------
    
    func setWordHovered(word: String, hovering: Bool, frame: CGRect) {
        
        isWordHovered = hovering
            
        if hovering {
            createSuggestionWindow(word: word, bounds: frame)
        }
        
    }
    
    func setSuggestionHovered(hovering: Bool) {

        isSuggestionHovered = hovering
            
        if !hovering && !isWordHovered {
            deleteSuggestionOverlay()
        }
        
    }
    
    // ------------------------ CLEANUP / DELETERS ------------------------
    
    func deleteAll() {
        
        deleteBorderOverlay()
        deleteTextOverlay()
        deleteSuggestionOverlay()
        
    }
    
    func stopTimer() {
        
        timer?.invalidate()
        
    }
    
    func deleteBorderOverlay() {
        
        borderWindow?.close()
        
    }
    
    func deleteTextOverlay() {
        
        wordOverlays.forEach { $0.0.close() }
        wordOverlays.removeAll()
        
    }
    
    func deleteSuggestionOverlay() {
        
        suggestionOverlay?.close()
        
    }
    
// -----V FOR DEBUGGING - DELETE LATER V ----------------------------------
    
    func createBorderOverlay(for frame: CGRect) {
        
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

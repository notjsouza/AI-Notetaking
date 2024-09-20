//
//  OverlayModel.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/21/24.
//

import Foundation
import SwiftUI

struct OverlayItem {
    let wordWindow: NSWindow
    let wordBounds: CGRect
    let word: String
    var suggestionWindow: NSWindow?
}

struct Note: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var content: String
    var keywords: [String]
    
    init(id: String, title: String, content: String, keywords: [String]) {
        self.id = id
        self.title = title
        self.content = content
        self.keywords = keywords
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

struct NoteWindow: Codable, Identifiable, Hashable {
    let id: UUID
    let note: Note
    var position: CGPoint
    var bounds: CGRect
    
    init(note: Note, position: CGPoint, bounds: CGRect) {
        self.id = UUID()
        self.note = note
        self.position = position
        self.bounds = bounds
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NoteWindow, rhs: NoteWindow) -> Bool {
        lhs.id == rhs.id
    }
}

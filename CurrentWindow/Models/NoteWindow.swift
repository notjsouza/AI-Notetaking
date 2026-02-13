//
//  NoteWindow.swift
//  CurrentWindow
//
//  Model for displaying a note in a floating window
//

import Foundation

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

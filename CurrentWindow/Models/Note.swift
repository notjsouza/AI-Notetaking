//
//  Note.swift
//  CurrentWindow
//
//  Model for a note from the backend
//

import Foundation

struct Note: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var content: String
    
    init(id: String = UUID().uuidString, title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

//
//  OverlayView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/25/24.
//

import SwiftUI

struct WordOverlayView: View {

    @StateObject private var controller = OverlayController.shared
    @State private var isHovered: Bool = false
    
    let word: String
    let frame: CGRect

    var body: some View {
        VStack {
            Text(word)
                .background(isHovered ? Color.green.opacity(0.25) : Color.clear)
                .foregroundColor(Color.clear)
                .font(.system(size: 14))
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHovered = hovering
                        controller.setWordHovered(word: word, hovering: hovering, frame: frame)
                    }
                }
                .offset(y: frame.height)
            .frame(width: frame.width, height: frame.height)
            
            Rectangle()
                .fill(Color.green.opacity(1))
                .frame(width: frame.width, height: frame.height * 0.5)
                .offset(y: frame.height * 0.4)
        }
    }
}


struct SuggestionView: View {
    
    @StateObject private var controller = OverlayController.shared
    let suggestions: [Note]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Suggestions")
                .font(.headline)
            
            Divider()
            
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button(action: {
                    controller.setNoteSelected(note: suggestion)
                }) {
                    Text(suggestion.title)
                        .foregroundColor(.blue)
                        .frame(alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Dismiss")
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .background(Color.white)
        .foregroundColor(Color.black)
        .cornerRadius(12)
        .shadow(radius: 5)
        .fixedSize(horizontal: true, vertical: true)
        .onHover { hovering in
            controller.setSuggestionHovered(hovering: hovering)
        }
    }
}


// WIP -----------------------------------------------------------
struct NoteView: View {
    
    let note: Note
    let onDismiss: () -> Void
    
    var body: some View {
        
        VStack {
            Text(note.title)
                .font(.headline)
            
            Divider()
            
            Text(note.content)
            
            Divider()
            
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Dismiss")
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .frame(width: 250)
        .background(Color.white)
        .foregroundColor(Color.black)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

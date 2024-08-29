//
//  OverlayView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/25/24.
//

import SwiftUI

struct WordOverlayView: View {
    
    @StateObject private var controller = OverlayController.shared
    let word: String
    let frame: CGRect
    
    var body: some View {
        
        VStack {
            Text(word)
                .background(Color.green.opacity(0.2))
                .frame(height: controller.isWordHovered ? 100: 5)
                .offset(y: controller.isWordHovered ? 0 : 95)
                .foregroundColor(Color.clear)
                .font(.system(size: 14))
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        controller.setWordHovered(word: word, hovering: hovering, frame: frame)
                    }
                }
            .frame(width: frame.width, height: frame.height)
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

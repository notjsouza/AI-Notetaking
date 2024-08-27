//
//  OverlayView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/25/24.
//

import SwiftUI

struct WordOverlayView: View {
    
    @StateObject private var controller = OverlayController()
    let word: String
    let frame: CGRect
    
    let suggestions: [Note]
    let onDismiss: () -> Void
    
    var body: some View {
        
        var isHovered: Bool = false
        
        VStack {
            Text(word)
                .background(controller.isWordHovered ? Color.green.opacity(0.2) : Color.clear)
                .foregroundColor(Color.clear)
                .font(.system(size: 14))
                .onHover { hovering in
                    isHovered = hovering
                }
            .frame(width: frame.width, height: frame.height)
            
            if isHovered {
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Suggestions")
                        .font(.headline)
                    
                    Divider()
                    
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        Button(action: {
                            print("Selected: \(suggestion.title)")
                            print(suggestion.content)
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
                
            }
            
        }
        
    }
}

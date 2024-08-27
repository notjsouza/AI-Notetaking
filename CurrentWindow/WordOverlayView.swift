//
//  WordOverlayView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/10/24.
//

import SwiftUI

struct WordOverlayView: View {
    
    let word: String
    let frame: CGRect
    @State var isHovered = false
    
    @StateObject var windowManager = WindowManager()
    
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.1)
            Text(word)
                .background(isHovered ? Color.green.opacity(0.2) : Color.clear)
                .foregroundColor(Color.clear)
                .font(.system(size: 14))
                .onHover { hovering in
                    isHovered = hovering
                }
            
            if isHovered {
                SuggestionView(suggestions: ["Suggestion 1", "Suggestion 2"], onDismiss: { isHovered = false })
                    .frame(width: 200, height: 150)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .offset(x: 0, y: frame.height - 100)
            }
        }
        .frame(width: frame.width, height: frame.height)
    }
}

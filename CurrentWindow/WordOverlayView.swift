//
//  WordOverlayView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/10/24.
//

import SwiftUI

struct WordOverlayView: View {
    
    let word: String
    @State private var isHovered = false
    
    var body: some View {
        
        Text(word)
            .padding(4)
            .background(isHovered ? Color.green.opacity(0.2) : Color.clear)
            .foregroundColor(Color.black)
            .onHover { hovering in
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    
                    isHovered = hovering
                    
                }
            }
            .onTapGesture {
                
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(word, forType: .string)
                
            }
        
    }
    
}

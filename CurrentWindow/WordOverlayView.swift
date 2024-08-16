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
            .padding(2)
            .background(Color.green.opacity(0.2))//isHovered ? Color.green.opacity(0.2) : Color.clear)
            .foregroundColor(Color.black)
            .font(.system(size: 12))
            .onHover { hovering in
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    
                    isHovered = hovering
                    print("Hovering over \(word)")
                    
                }
            }
            .onTapGesture {
                
                print("Text Pressed")
                
            }
        
    }
    
}

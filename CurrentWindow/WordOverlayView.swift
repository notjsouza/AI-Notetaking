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
    @State private var isHovered = false
    
    var body: some View {
        
        Text(word)
            .background(Color.green.opacity(0.2))//isHovered ? Color.green.opacity(0.2) : Color.clear)
            .foregroundColor(Color.black)
            .font(.system(size: 14))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                    if hovering {
                        OverlayModel.shared.fetchNote(for: word)
                    }
                }
            }
            .onTapGesture {
                // OPEN NOTE IN ANOTHER WINDOW
            }
            .popover(isPresented: .constant(isHovered)) {
                Text(OverlayModel.shared.note)
                    .padding()
            }
    }
    
}

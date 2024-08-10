//
//  HoverableText.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/2/24.
//

import SwiftUI

struct HoverableText: View {
    
    let fullText: String
    
    @Binding var selectedText: String
    @State private var hoveredSegmentIndex: Int?
    
    var body: some View {
        
        let segments = createSegments(from: fullText)
        
        /*
        let words = fullText.split(separator: " ")
        let segments = createSegments(from: words)
        */
         
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                Text(segment)
                    .padding(2)
                    .background(hoveredSegmentIndex == index ? Color.green.opacity(0.2) : Color.clear)
                    .foregroundColor(.black)
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredSegmentIndex = isHovered ? index : nil
                        }
                    }
                    .onTapGesture {
                        selectedText = segment
                    }
            }
        }
    }
    
    private func createSegments(from text: String) -> [String] {
        
        let words = text.split(separator: " ")
        var segments: [String] = []
        
        for i in stride(from: 0, to: words.count, by: 3) {
            
            let endIndex = min(i + 3, words.count)
            let segment = words[i..<endIndex].joined(separator: " ")
            segments.append(segment)
            
        }
        
        return segments
        
    }
    
}

//
//  SuggestionView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/24/24.
//

import SwiftUI

struct SuggestionView: View {
    
    let suggestions: [String]
    let onDismiss: () -> Void

    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestions")
                .font(.headline)
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button(action: {
                    print("Selected: \(suggestion)")
                }) {
                    Text(suggestion)
                        .foregroundColor(.blue)
                }
            }
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Dismiss")
                }
            }
        }
        .padding()
        .background(Color.white)
        .foregroundColor(Color.black)
        .cornerRadius(8)
        .shadow(radius: 5)
    }
    
}

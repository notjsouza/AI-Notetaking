//
//  ContentView.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import SwiftUI

struct OverlayContentView: View {
    
    @ObservedObject var appDelegate: AppDelegate
    @State private var selectedText: String = ""
    
    var body: some View {
        
        HoverableText(
            fullText: appDelegate.activeTextField,
            selectedText: $selectedText
        )
        .background(Color.black.opacity(0.1))
        
    }
}

/*
import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var text: String = ""
    @State private var selectedText: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                HoverableText(
                    fullText: appDelegate.activeTextField,
                    selectedText: $selectedText
                )
                .padding()
            }
            
            Text("Selected text: \(selectedText)")
                .padding()
            
        }
            
            .onChange(of: appDelegate.activeTextField) { newValue in
                text = newValue
            }
        }
    }

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}
*/

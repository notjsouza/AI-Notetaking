//
//  CurrentWindowApp.swift
//  CurrentWindow
//
//  Created by Justin Souza on 7/9/24.
//

import SwiftUI

@main
struct CurrentWindowApp: App {

    @NSApplicationDelegateAdaptor (AppDelegate.self) var appDelegate
    
    init() {
            requestAccessibilityPermission()
        }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("Accessibility access enabled: \(accessEnabled)")
    }
}

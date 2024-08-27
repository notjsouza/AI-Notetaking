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
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

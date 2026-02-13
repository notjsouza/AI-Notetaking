//
//  OverlayItem.swift
//  CurrentWindow
//
//  Model representing a word overlay with optional suggestion window
//

import AppKit

struct OverlayItem {
    let wordWindow: NSWindow
    let wordBounds: CGRect
    let word: String
    var suggestionWindow: NSWindow?
}

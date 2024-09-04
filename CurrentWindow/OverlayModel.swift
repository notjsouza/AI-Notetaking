//
//  OverlayModel.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/21/24.
//

import Foundation

struct Note: Codable {
    let title: String
    let content: String
}

struct WordBoundingBox {
    let word: String
    let frame: CGRect
}

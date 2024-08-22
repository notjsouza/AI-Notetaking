//
//  OverlayModel.swift
//  CurrentWindow
//
//  Created by Justin Souza on 8/21/24.
//

import SwiftUI

class OverlayModel: ObservableObject {
    
    @Published var note: String = ""
    
    static let shared = OverlayModel()
    
    func fetchNote(for word: String) {
        
        guard let url = URL(string: "http://127.0.0.1:5000/get_note") else { 
            print("Failed to get url")
            return
        }
        
        print("Successfully fetched URL")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["word": word]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data recieved")
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode(NoteResponse.self, from: data) {
                self.note = decodedResponse.note
            } else {
                print("Failed to decode response")
            }
        }.resume()
        
    }
    
}

struct NoteResponse: Codable {
    let note: String
}

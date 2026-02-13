//
//  NotesServiceClient.swift
//  CurrentWindow
//
//  Handles HTTP communication with the Flask backend
//

import Foundation

class NotesServiceClient {
    
    private let baseURL = "http://127.0.0.1:5000"
    
    /// Initialize the notes index on the backend
    func initializeIndex() async throws -> String? {
        guard let url = URL(string: "\(baseURL)/initialize") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return json?["message"] as? String
    }
    
    /// Filter text to remove stopwords (server-side filtering)
    func filterText(_ text: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/filter_text") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return json?["filtered_words"] as? [String] ?? []
    }
    
    /// Search for notes related to multiple words (batch request)
    func searchNotesBatch(words: [String]) async throws -> [String: [Note]] {
        guard let url = URL(string: "\(baseURL)/search_batch") else {
            print("Failed to get url")
            return [:]
        }
        
        if words.isEmpty {
            print("No words to search in batch")
            return [:]
        }
        
        print("Batch searching \(words.count) words: \(words.prefix(5).joined(separator: ", "))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: [String]] = ["queries": words]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status code
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = errorJson["error"] as? String {
                    print("Batch search error (\(httpResponse.statusCode)): \(errorMsg)")
                } else {
                    print("Batch search failed with status code: \(httpResponse.statusCode)")
                }
                return [:]
            }
        }
        
        guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [[String: String]]] else {
            print("Failed to parse batch search response")
            if let responseStr = String(data: data, encoding: .utf8) {
                print("Response was: \(responseStr.prefix(200))")
            }
            return [:]
        }
        
        var results: [String: [Note]] = [:]
        for (word, notesData) in jsonResult {
            let notes = notesData.map { noteData in
                Note(id: noteData["id"] ?? UUID().uuidString,
                     title: noteData["title"] ?? "",
                     content: noteData["content"] ?? "")
            }
            if !notes.isEmpty {
                results[word] = notes
            }
        }
        
        print("Batch search found notes for \(results.count) words")
        return results
    }
}

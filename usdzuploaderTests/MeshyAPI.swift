//
//  MeshyAPI.swift
//  usdzuploaderTests
//
//  Created by WorkMerkDev on 6/28/24.
//

import Foundation

class MeshyAPITest {
    static let shared = MeshyAPITest()
    
    public init() {}
    
    func generate3DModel(from prompt: String, progressUpdate: @escaping (Double) -> Void, completion: @escaping (URL?) -> Void) {
        guard let apiKey = ProcessInfo.processInfo.environment["MESHY_API_KEY"] else {
            print("API key is missing.")
            completion(nil)
            return
        }

        let url = URL(string: "https://api.meshy.ai/v2/text-to-3d")! // Corrected endpoint
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "prompt": prompt,
            "mode": "preview",
            "art_style": "realistic",
            "negative_prompt": "low quality, low resolution, low poly, ugly"
        ]

        // Print the JSON request
        if let requestData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let requestString = String(data: requestData, encoding: .utf8) {
            print("JSON Request: \(requestString)")
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            // Print the JSON response
            if let responseString = String(data: data, encoding: .utf8) {
                print("JSON Response: \(responseString)")
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["result"] as? String {
                    // Start polling the task status
                    self.pollTaskStatus(taskID: result, progressUpdate: progressUpdate, completion: completion)
                } else {
                    print("Failed to parse response: \(String(data: data, encoding: .utf8) ?? "No data")")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
    
    private func pollTaskStatus(taskID: String, progressUpdate: @escaping (Double) -> Void, completion: @escaping (URL?) -> Void) {
        guard let apiKey = ProcessInfo.processInfo.environment["MESHY_API_KEY"] else {
            print("API key is missing.")
            completion(nil)
            return
        }

        let url = URL(string: "https://api.meshy.ai/v2/text-to-3d/\(taskID)")! // Endpoint to fetch model by task ID
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            // Print the JSON response
            if let responseString = String(data: data, encoding: .utf8) {
                print("JSON Response: \(responseString)")
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   let progress = json["progress"] as? Double,
                   let modelURLs = json["model_urls"] as? [String: String] {
                    // Print the progress to console
                    print("Progress: \(progress)%")
                    progressUpdate(progress)
                    if status == "SUCCEEDED", let usdzURLString = modelURLs["usdz"], let usdzURL = URL(string: usdzURLString) {
                        print("Download URL: \(usdzURL)")
                        completion(usdzURL)
                    } else if status == "FAILED" {
                        print("Task failed.")
                        completion(nil)
                    } else {
                        // Task is still in progress, poll again after a delay
                        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                            self.pollTaskStatus(taskID: taskID, progressUpdate: progressUpdate, completion: completion)
                        }
                    }
                } else {
                    print("Failed to parse model URL: \(String(data: data, encoding: .utf8) ?? "No data")")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}











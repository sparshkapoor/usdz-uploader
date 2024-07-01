//
//  DocumentHandler.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/19/24.
//

import UIKit

class DocumentHandler {
    static func presentDocumentPicker(from viewController: UIViewController, delegate: UIDocumentPickerDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.usdz, .json])
        documentPicker.delegate = delegate
        documentPicker.allowsMultipleSelection = false
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    static func handleDocumentPicker(urls: [URL], viewController: ARViewController) {
        guard let url = urls.first else { return }
        print("Selected file URL: \(url)")

        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let fileCoordinator = NSFileCoordinator()
                var error: NSError?
                var targetURL: URL?

                fileCoordinator.coordinate(readingItemAt: url, options: [], error: &error) { (newURL) in
                    targetURL = newURL
                }

                if let targetURL = targetURL {
                    copyAndLoadUSDZModel(from: targetURL, viewController: viewController)
                } else if let error = error {
                    print("File coordination error: \(error)")
                }
            } catch {
                print("Error accessing security scoped resource: \(error)")
            }
        } else {
            print("Unable to access security scoped resource")
        }
    }

    static func handleScenePicker(urls: [URL], viewController: ARViewController) {
        guard let url = urls.first else { return }
        viewController.loadScene(from: url)
    }

    static func saveSceneFile(jsonData: Data, sceneName: String, from viewController: UIViewController) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sceneURL = documentsDirectory.appendingPathComponent("\(sceneName).json")
        do {
            try jsonData.write(to: sceneURL)
            print("Scene saved to directory: \(sceneURL)")
        } catch {
            print("Failed to write JSON data to file: \(error)")
        }
    }


    static func copyAndLoadUSDZModel(from url: URL, viewController: ARViewController) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            print("File copied to Documents directory: \(destinationURL)")
            viewController.loadUSDZModel(from: destinationURL)
        } catch {
            print("Failed to copy file to Documents directory: \(error)")
        }
    }
}




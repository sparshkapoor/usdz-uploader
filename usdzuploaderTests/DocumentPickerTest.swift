//
//  DocumentPickerTest.swift
//  usdzuploaderTests
//
//  Created by WorkMerkDev on 6/28/24.
//

import SwiftUI
import UIKit

struct DocumentPickerTest: UIViewControllerRepresentable {
    var url: URL?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        guard let url = url else {
            fatalError("URL is nil")
        }
        
        let picker = UIDocumentPickerViewController(forExporting: [url])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update necessary
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerTest
        
        init(_ parent: DocumentPickerTest) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let pickedURL = urls.first else {
                return
            }
            print("Picked URL: \(pickedURL)")
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
    }
}


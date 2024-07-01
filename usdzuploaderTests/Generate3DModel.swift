//
//  Generate3DModel.swift
//  usdzuploaderTests
//
//  Created by WorkMerkDev on 6/28/24.
//

import SwiftUI
import Combine
import RealityKit

struct Generate3DModelTest: View {
    var onSave: (String, URL) -> Void
    var api: MeshyAPITest

    @State public var prompt: String = ""
    @State public var modelURL: URL? = nil
    @State public var progress: Double = 0.0
    @State public var isGenerating: Bool = false
    @State public var showDocumentPicker = false
    @State public var showSaveButton = false
    @State public var showProgress = false
    @State public var showAlert = false
    @State public var showNamePrompt = false
    @State public var modelName: String = ""
    @FocusState public var focus: Bool
    @State public var subscriptions = Set<AnyCancellable>()
    @AppStorage("generatedModels")
    var generatedModels: String = String()

    var body: some View {
        VStack {
            if let modelURL = modelURL, !focus {
                Model3DViewTest(fileURL: modelURL)
                    .frame(height: 300)
            }

            TextEditor(text: $prompt)
                .padding()
                .border(Color.gray, width: 1)
                .frame(maxWidth: .infinity, maxHeight: 150)
                .focused($focus)
                .accessibilityIdentifier("promptTextEditor")

            Button(action: {
                if modelURL != nil {
                    showAlert = true
                } else {
                    resetAndGenerateModel()
                }
            }) {
                Text("Generate")
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(isGenerating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            .disabled(isGenerating)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Are you sure you want to delete your model?"),
                    primaryButton: .destructive(Text("Yes")) {
                        resetAndGenerateModel()
                    },
                    secondaryButton: .cancel(Text("No"))
                )
            }
            .accessibilityIdentifier("generateButton")

            if showProgress {
                Text("Progress:")

                ZStack(alignment: .leading) {
                    ProgressView(value: progress, total: 1.0)
                        .padding()
                        .progressViewStyle(LinearProgressViewStyle())
                        .accessibilityIdentifier("progressView")

                    GeometryReader { geometry in
                        Text("\(Int(progress * 100))%")
                            .position(x: CGFloat(progress) * (geometry.size.width - 40) + 15, y: geometry.size.height + 10)
                    }
                    .frame(height: 20)
                }
                .frame(height: 40)
            }

            if showSaveButton {
                Button(action: {
                    showNamePrompt = true
                }) {
                    Text("Save Model")
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                .sheet(isPresented: $showNamePrompt) {
                    VStack {
                        Text("Enter Model Name:")
                        TextField("Model Name", text: $modelName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Button("Save") {
                            saveModel()
                            showNamePrompt = false
                        }
                        .padding()
                    }
                    .frame(width: 300, height: 200)
                    .padding()
                }
                .accessibilityIdentifier("saveButton")
            }
        }
        .padding()
        .sheet(isPresented: $showDocumentPicker, content: {
            DocumentPickerTest(url: modelURL)
        })
        .accessibilityIdentifier("MainView")
    }

    internal func resetAndGenerateModel() {
        isGenerating = true
        showSaveButton = false
        showProgress = true
        modelURL = nil
        focus = false

        api.generate3DModel(from: prompt, progressUpdate: { progress in
            DispatchQueue.main.async {
                withAnimation {
                    self.progress = progress / 100.0
                }
            }
        }) { url in
            DispatchQueue.main.async {
                guard let remoteURL = url else {
                    self.isGenerating = false
                    self.showAlert = true
                    return
                }

                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = documentsURL.appendingPathComponent(remoteURL.lastPathComponent)

                URLSession.shared.downloadTask(with: remoteURL) { localURL, response, error in
                    guard let localURL = localURL else {
                        print("Download failed: \(error?.localizedDescription ?? "No error description")")
                        self.isGenerating = false
                        return
                    }

                    do {
                        if fileManager.fileExists(atPath: destinationURL.path) {
                            try fileManager.removeItem(at: destinationURL)
                        }
                        try fileManager.moveItem(at: localURL, to: destinationURL)

                        DispatchQueue.main.async {
                            self.modelURL = destinationURL
                            self.isGenerating = false
                            print("Model downloaded to: \(destinationURL)")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self.showSaveButton = true
                            }
                        }
                    } catch {
                        print("Error saving model: \(error.localizedDescription)")
                        self.isGenerating = false
                    }
                }.resume()
            }
        }
    }

    private func saveModel() {
        guard let modelURL = modelURL else { return }
        guard !modelName.isEmpty else { return }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(modelName).appendingPathExtension("usdz")

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: modelURL, to: destinationURL)

            DispatchQueue.main.async {
                self.modelURL = destinationURL
                self.generatedModels.append("\n\(destinationURL.lastPathComponent)")
                self.onSave(destinationURL.lastPathComponent, destinationURL)
            }
        } catch {
            print("Error saving model: \(error.localizedDescription)")
        }
    }
}


//
//  Generate3DModel.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/27/24.
//

import SwiftUI
import Combine
import RealityKit
import QuickLookThumbnailing
import ConfettiSwiftUI

struct Generate3DModel: View {
    var onSave: (String, URL) -> Void

    @State private var prompt: String = ""
    @State private var modelURL: URL? = nil
    @State private var progress: Double = 0.0
    @State private var isGenerating: Bool = false
    @State private var showDocumentPicker = false
    @State private var showSaveButton = false
    @State private var showProgress = false
    @State private var showAlert = false
    @State private var showNamePrompt = false
    @State private var modelName: String = ""
    @State private var ellipsesState: Int = 0
    @FocusState private var focus: Bool
    @State private var subscriptions = Set<AnyCancellable>()
    @AppStorage("generatedModels")
    var generatedModels: String = String()
    
    // Animation state
    @State private var generatingText: String = "Generating"
    @State private var showConfetti = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Transparent background to capture tap gestures
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    print("Tap gesture captured, dismissing keyboard and removing focus from TextEditor.")
                    focus = false // Dismiss the keyboard when tapping outside the TextEditor
                }
            VStack {
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: 80, height: 5)
                        .cornerRadius(2.5)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    Spacer()
                        .frame(maxHeight: 10)
                }
                if let modelURL = modelURL, !focus {
                    Model3DView(fileURL: modelURL)
                        .frame(height: 300) // Adjust height as needed
                }

                TextEditor(text: $prompt)
                    .padding()
                    .border(Color.gray, width: 1)
                    .focused($focus)
                    .frame(maxWidth: .infinity, maxHeight: 150)

                Button(action: {
                    if modelURL != nil {
                        showAlert = true
                    } else {
                        resetAndGenerateModel()
                    }
                }) {
                    Text(isGenerating ? generatingText : "Generate")
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

                if showProgress {
                    Text("Progress:")

                    ZStack(alignment: .leading) {
                        ProgressView(value: progress, total: 1.0)
                            .padding()
                            .progressViewStyle(LinearProgressViewStyle())

                        GeometryReader { geometry in
                            Text("\(Int(progress * 100))%")
                                .position(x: CGFloat(progress) * (geometry.size.width - 40) + 20, y: geometry.size.height + 10)
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
                            Text("Enter Model Name")
                            TextField("Model Name", text: $modelName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            Button("Save") {
                                saveModel()
                                showNamePrompt = false
                            }
                            .padding()
                        }
                        .frame(width: 300, height: 150)
                        .padding()
                    }
                }
            }
            .padding()
            .onAppear {
                startGeneratingTextAnimation()
            }
            .confettiCannon(counter: $showConfetti, rainHeight: 800, radius: 600, repetitions: 3, repetitionInterval: 0.6)
        }
    }

    private func resetAndGenerateModel() {
        isGenerating = true
        showSaveButton = false
        showProgress = true
        modelURL = nil
        focus = false

        MeshyAPI.shared.generate3DModel(from: prompt, progressUpdate: { progress in
            DispatchQueue.main.async {
                withAnimation {
                    self.progress = progress / 100.0
                }
            }
        }) { url in
            DispatchQueue.main.async {
                guard let remoteURL = url else {
                    self.isGenerating = false
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
                                self.showConfetti += 1 // Increment the counter
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

        let trimmedModelName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(trimmedModelName).appendingPathExtension("usdz")

        do {
            // Check if the file already exists at the destination and remove it if necessary
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Move the file to the destination
            try fileManager.moveItem(at: modelURL, to: destinationURL)

            DispatchQueue.main.async {
                self.modelURL = destinationURL
                self.generatedModels.append("\n\(destinationURL.lastPathComponent)")
                self.onSave(destinationURL.lastPathComponent, destinationURL)

                // Save to Files app
                showDocumentPicker = true
            }
        } catch {
            print("Error saving model: \(error.localizedDescription)")
        }
    }
    
    private func startGeneratingTextAnimation() {
        guard isGenerating else {
            timer?.invalidate()
            timer = nil
            generatingText = "Generating"
            return
        }

        switch ellipsesState {
        case 0:
            generatingText = "Generating."
        case 1:
            generatingText = "Generating.."
        case 2:
            generatingText = "Generating..."
        default:
            generatingText = "Generating"
        }

        ellipsesState = (ellipsesState + 1) % 4
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var url: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url!])
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

struct Generate3DModel_Previews: PreviewProvider {
    static var previews: some View {
        Generate3DModel(onSave: { _, _ in })
    }
}

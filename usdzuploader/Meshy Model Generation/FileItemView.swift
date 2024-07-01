//
//  FileItemView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/28/24.
//

import SwiftUI

struct FileItemView: View {
    let modelName: String
    let url: URL
    let deleteModel: (String) -> Void
    let saveToFile: (URL) -> Void
    @AppStorage("generatedModels") private var generatedModels: String = String()
    @State private var isFocused: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var showingRenamePopup = false
    @State private var newModelName: String = ""
    private let fileManager = FileManager.default

    var body: some View {
        VStack {
            ThumbnailImageView(url: url)
                .frame(width: 120, height: 120) // Adjusted frame size
                .cornerRadius(10)
                .scaleEffect(scale)
                .onLongPressGesture {
                    withAnimation {
                        isFocused.toggle()
                        scale = isFocused ? 1.2 : 1.0
                    }
                }
                .contextMenu {
                    Button(action: { viewModel() }) {
                        Text("View")
                        Image(systemName: "eye")
                    }
                    Button(action: { saveToFile(url) }) {
                        Text("Download")
                        Image(systemName: "square.and.arrow.down")
                    }
                    Button(action: { deleteModel(modelName) }) {
                        Text("Delete")
                            .foregroundStyle(Color.red)
                        Image(systemName: "trash")
                            .foregroundStyle(Color.red)
                    }
                }

            Text(modelName)
                .font(.caption)
                .lineLimit(1)
                .padding(.top, 5)
        }
        .sheet(isPresented: $showingRenamePopup) {
            VStack {
                Text("Rename Model")
                    .font(.headline)
                    .padding()
                TextField("New Model Name", text: $newModelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button(action: { showingRenamePopup = false }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button(action: { performRename(newName: newModelName) }) {
                        Text("Rename")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .frame(width: 300, height: 200)
            .padding()
        }
    }

    private func renameModel() {
        newModelName = modelName
        showingRenamePopup = true
    }

    private func performRename(newName: String) {
        let oldURL = url
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(oldURL.pathExtension)
        
        do {
            try fileManager.moveItem(at: oldURL, to: newURL)
            updateModelName(oldName: modelName, newName: newName)
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
        }
        showingRenamePopup = false
    }

    private func updateModelName(oldName: String, newName: String) {
        var models = generatedModels.split(separator: "\n").map { String($0) }
        if let index = models.firstIndex(of: oldName) {
            models[index] = newName
            generatedModels = models.joined(separator: "\n")
        }
    }

    private func viewModel() {
        let model3DView = UIHostingController(rootView: Model3DView(fileURL: url))
        UIApplication.shared.windows.first?.rootViewController?.present(model3DView, animated: true, completion: nil)
    }
}

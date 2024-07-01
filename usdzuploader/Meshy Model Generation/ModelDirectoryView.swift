//
//  ModelDirectoryView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/27/24.
//

import SwiftUI

struct ModelDirectoryView: View {
    @State private var searchText: String = ""
    @AppStorage("generatedModels") private var generatedModels: String = String()
    private let fileManager = FileManager.default

    var body: some View {
        ZStack {
            // Transparent background to capture tap gestures
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    print("Tap gesture captured, dismissing keyboard and removing focus from TextField.")
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

            VStack {
                Button(action: {
                    let generate3DModelView = UIHostingController(rootView: Generate3DModel(onSave: { modelName, modelURL in
                        saveModel(named: modelName)
                    }))
                    UIApplication.shared.windows.first?.rootViewController?.present(generate3DModelView, animated: true, completion: nil)
                }) {
                    Text("Create Model")
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                    TextField("Search Models", text: $searchText)
                        .padding(7)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                .padding()
                .background(Color(.clear))
                .cornerRadius(10)
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                        ForEach(filteredModels(), id: \.self) { modelName in
                            if let url = getModelURL(for: modelName) {
                                FileItemView(modelName: modelName, url: url, deleteModel: deleteModel, saveToFile: saveToFile)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }

    private func filteredModels() -> [String] {
        let models = generatedModels.split(separator: "\n").map { String($0) }
        if searchText.isEmpty {
            return models
        } else {
            return models.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }

    private func getModelURL(for modelName: String) -> URL? {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(modelName)
    }

    private func saveModel(named modelName: String) {
        var models = generatedModels.split(separator: "\n").map { String($0) }
        if !models.contains(modelName) {
            models.append(modelName)
            generatedModels = models.joined(separator: "\n")
        }
    }

    private func deleteModel(named modelName: String) {
        var models = generatedModels.split(separator: "\n").map { String($0) }
        if let index = models.firstIndex(of: modelName) {
            models.remove(at: index)
            generatedModels = models.joined(separator: "\n")
        }
    }

    private func saveToFile(url: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [url])
        documentPicker.delegate = UIApplication.shared.windows.first?.rootViewController as? UIDocumentPickerDelegate
        UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true, completion: nil)
    }
}

struct ModelDirectoryView_Previews: PreviewProvider {
    static var previews: some View {
        ModelDirectoryView()
    }
}

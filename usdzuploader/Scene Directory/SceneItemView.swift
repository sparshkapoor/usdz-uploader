//
//  SceneItemView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 7/1/24.
//

import SwiftUI

struct SceneItemView: View {
    let sceneURL: URL
    let loadScene: (URL) -> Void
    @State private var isExpanded: Bool = false
    private let fileManager = FileManager.default
    let isEditing: Bool
    let isSelected: Bool
    let toggleSelection: () -> Void

    var body: some View {
        VStack {
            HStack {
                if isEditing {
                    Button(action: toggleSelection) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                    }
                }
                Text(sceneURL.deletingPathExtension().lastPathComponent)
                    .font(.headline)
                Spacer()
                if !isEditing {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(10)

            if isExpanded {
                VStack {
                    ForEach(getModelsInScene(), id: \.self) { model in
                        HStack {
                            ThumbnailImageView(url: getModelURL(for: model))
                                .frame(width: 50, height: 50)
                                .cornerRadius(5)
                            Text(model)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
    }

    private func getModelsInScene() -> [String] {
        do {
            let jsonData = try Data(contentsOf: sceneURL)
            if let sceneDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let modelData = sceneDict["models"] as? [[String: Any]] {
                return modelData.compactMap { $0["fileName"] as? String }
            }
        } catch {
            print("Error loading scene models: \(error)")
        }
        return []
    }

    private func getModelURL(for modelName: String) -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(modelName)
    }
}

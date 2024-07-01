//
//  SceneDirectoryView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 7/1/24.
//

import SwiftUI

struct SceneDirectoryView: View {
    @State private var searchText: String = ""
    @State private var scenes: [URL] = [] // Store URLs directly
    @State private var isEditing: Bool = false
    @State private var selectedScenes: Set<URL> = []
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
                HStack {
                    Button(action: {
                        isEditing.toggle()
                        if !isEditing {
                            selectedScenes.removeAll()
                        }
                    }) {
                        Text("Edit")
                    }
                    .padding()

                    Spacer()

                    if isEditing {
                        Button(action: {
                            if selectedScenes.isEmpty {
                                isEditing = false
                            } else {
                                deleteSelectedScenes()
                            }
                        }) {
                            Text(selectedScenes.isEmpty ? "Done" : "Delete")
                        }
                        .padding()
                    }
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                    TextField("Search Scenes", text: $searchText)
                        .padding(7)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                .padding()
                .background(Color.clear)
                .cornerRadius(10)
                .padding()

                List {
                    ForEach(filteredScenes(), id: \.self) { sceneURL in
                        SceneItemView(
                            sceneURL: sceneURL,
                            loadScene: loadScene,
                            isEditing: isEditing,
                            isSelected: selectedScenes.contains(sceneURL),
                            toggleSelection: {
                                toggleSelection(for: sceneURL)
                            }
                        )
                    }
                    .onMove(perform: moveScenes)
                }
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
            .onAppear(perform: loadScenes)
        }
    }

    private func loadScenes() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = directoryContents.filter { $0.pathExtension == "json" }
            scenes = jsonFiles
        } catch {
            print("Error loading scenes: \(error)")
        }
    }

    private func filteredScenes() -> [URL] {
        if searchText.isEmpty {
            return scenes
        } else {
            return scenes.filter { $0.lastPathComponent.lowercased().contains(searchText.lowercased()) }
        }
    }

    private func loadScene(sceneURL: URL) {
        print("Attempting to load scene from URL: \(sceneURL)")
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController,
           let arViewController = rootViewController.viewControllers?.first(where: { $0 is ARViewController }) as? ARViewController {
            arViewController.loadScene(from: sceneURL)
            rootViewController.selectedIndex = 0 // Switch to AR view tab
        } else {
            print("Failed to find ARViewController")
        }
    }

    private func deleteScenes(at offsets: IndexSet) {
        offsets.forEach { index in
            let sceneURL = scenes[index]
            deleteScene(at: sceneURL)
        }
    }

    private func deleteScene(at sceneURL: URL) {
        do {
            try fileManager.removeItem(at: sceneURL)
            loadScenes() // Refresh the scenes list
        } catch {
            print("Error deleting scene: \(error)")
        }
    }

    private func moveScenes(from source: IndexSet, to destination: Int) {
        scenes.move(fromOffsets: source, toOffset: destination)
    }

    private func toggleSelection(for sceneURL: URL) {
        if selectedScenes.contains(sceneURL) {
            selectedScenes.remove(sceneURL)
        } else {
            selectedScenes.insert(sceneURL)
        }
    }

    private func deleteSelectedScenes() {
        selectedScenes.forEach { deleteScene(at: $0) }
        selectedScenes.removeAll()
        isEditing = false
    }
}

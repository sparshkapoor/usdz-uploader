//
//  Model3DView.swift
//  usdzuploaderTests
//
//  Created by WorkMerkDev on 6/28/24.
//


import SwiftUI
import RealityKit

struct Model3DView: UIViewRepresentable {
    let fileURL: URL

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = true

        // Load the model
        loadModel(into: arView)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    public func loadModel(into arView: ARView) {
        do {
            let entity = try Entity.load(contentsOf: fileURL)
            let anchorEntity = AnchorEntity()
            anchorEntity.addChild(entity)
            arView.scene.anchors.removeAll() // Remove previous anchors
            arView.scene.addAnchor(anchorEntity)
            print("Model loaded and added to scene: \(entity)")
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
        }
    }
}



//
//  ThumbnailImageView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/27/24.
//

import SwiftUI
import SceneKit

struct ThumbnailImageView: View {
    let url: URL
    @State private var thumbnailImage: UIImage? = nil

    var body: some View {
        Group {
            if let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100) // Set to a larger frame size
                    .clipped()
            } else {
                Rectangle()
                    .foregroundColor(.gray)
                    .overlay(
                        Text("...")
                            .foregroundColor(.white)
                    )
                    .frame(width: 100, height: 100) // Set to a larger frame size
            }
        }
        .onAppear(perform: loadThumbnail)
    }

    private func loadThumbnail() {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheURL = cacheDirectory.appendingPathComponent(url.lastPathComponent).appendingPathExtension("png")

        // Check if cached thumbnail exists
        if let cachedImage = UIImage(contentsOfFile: cacheURL.path) {
            self.thumbnailImage = cachedImage
            return
        }

        DispatchQueue.global(qos: .background).async {
            guard let scene = try? SCNScene(url: url, options: nil) else {
                print("Failed to load USDZ file")
                return
            }

            // Add a camera to the scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
            cameraNode.camera?.fieldOfView = 50
            scene.rootNode.addChildNode(cameraNode)

            // Add a light to the scene
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            scene.rootNode.addChildNode(lightNode)

            // Add an ambient light to reduce shadows
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light?.type = .ambient
            ambientLightNode.light?.color = UIColor.darkGray
            scene.rootNode.addChildNode(ambientLightNode)

            // Increase the snapshot size for better quality
            let size = CGSize(width: 200, height: 200)
            let renderer = SCNRenderer(device: nil, options: nil)
            renderer.scene = scene

            let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)

            // Save the thumbnail to cache
            if let imageData = image.pngData() {
                try? imageData.write(to: cacheURL)
            }

            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }
    }
}










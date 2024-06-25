//
//  ARSessionManager.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/20/24.
//

import ARKit

class ARSessionManager {
    static func setupARSession(sceneView: ARSCNView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical] // Enable horizontal and vertical plane detection
        configuration.environmentTexturing = .automatic // Enable environment texturing
        sceneView.session.run(configuration)
    }

    static func resetARSession(sceneView: ARSCNView) {
        sceneView.session.pause()
        setupARSession(sceneView: sceneView)
    }
}

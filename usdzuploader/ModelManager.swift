//
//  ModelManager.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/20/24.
//

import ARKit

class ModelManager {
    
    
    static func loadUSDZModel(from url: URL, sceneView: ARSCNView) -> SCNNode? {
        print("Loading USDZ model from URL: \(url)")
        
        // Ensure the file exists at the specified URL
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at URL: \(url)")
            return nil
        }
        
        guard let referenceNode = SCNReferenceNode(url: url) else {
            print("Failed to create SCNReferenceNode from URL: \(url)")
            return nil
        }
        
        do {
            try referenceNode.load()
        } catch {
            print("Failed to load SCNReferenceNode: \(error)")
            return nil
        }
        
        // Debug logging for child nodes
        referenceNode.enumerateChildNodes { (child, _) in
            print("Child node: \(child)")
        }
        
        guard !referenceNode.childNodes.isEmpty else {
            print("No child nodes found in the model.")
            return nil
        }
        
        referenceNode.name = "ModelRoot"
        normalizeModelSize(modelNode: referenceNode, targetSize: 0.1)
        setShadowProperties(node: referenceNode)
        sceneView.scene.rootNode.addChildNode(referenceNode)
        
        print("Model loaded successfully at position: \(referenceNode.position) and scale: \(referenceNode.scale)")
        return referenceNode
    }
    
    static func normalizeModelSize(modelNode: SCNNode, targetSize: Float) {
        let (minVec, maxVec) = modelNode.boundingBox
        let boundingBoxSize = SCNVector3(
            maxVec.x - minVec.x,
            maxVec.y - minVec.y,
            maxVec.z - minVec.z
        )
        
        let maxDimension = max(boundingBoxSize.x, boundingBoxSize.y, boundingBoxSize.z)
        let scale = targetSize / maxDimension
        modelNode.scale = SCNVector3(scale, scale, scale)
        print("Normalized model scale to: \(modelNode.scale)")
    }
    
    static func setShadowProperties(node: SCNNode) {
        node.castsShadow = true
        node.enumerateChildNodes { (child, _) in
            child.castsShadow = true
        }
    }
}


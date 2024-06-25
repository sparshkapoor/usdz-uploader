//
//  ARViewController.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/19/24.
//

import UIKit
import ARKit
import SceneKit

class ARViewController: UIViewController, ARSCNViewDelegate, UIDocumentPickerDelegate, UIGestureRecognizerDelegate, CompassViewDelegate {

    var sceneView: ARSCNView!
    var models: [SCNNode] = []
    var modelURLs: [SCNNode: URL] = [:] // Dictionary to store URLs for models
    var selectedModel: SCNNode?
    var targetSize: Float = 0.1 // Target size to normalize the models to
    var targetSizeBubble: UILabel!
    var bubbleAnimator: UIViewPropertyAnimator?
    var rotationCompass: CompassView!
    var verticalSlider: UISlider!
    var initialModelPosition: SCNVector3?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup ARSCNView
        sceneView = ARSCNView(frame: self.view.frame)
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true // Enable default lighting
        self.view.addSubview(sceneView)

        // Setup AR Session
        ARSessionManager.setupARSession(sceneView: sceneView)

        // Add UI elements
        setupUI()

        // Add Gesture Recognizers for Model Removal, Selection, and Movement
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.delegate = self
        sceneView.addGestureRecognizer(longPressGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)

        // Setup lighting for shadows
        setupLighting()
    }

    func setupUI() {
        // Add Upload Button
        let uploadButton = UIButton(frame: CGRect(x: 20, y: self.view.frame.size.height - 60, width: self.view.frame.size.width - 40, height: 40))
        uploadButton.setTitle("Upload USDZ", for: .normal)
        uploadButton.backgroundColor = .systemBlue
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        self.view.addSubview(uploadButton)

        // Add Slider for Target Size
        let targetSizeSlider = UISlider(frame: CGRect(x: 20, y: self.view.frame.size.height - 160, width: self.view.frame.size.width - 40, height: 40))
        targetSizeSlider.minimumValue = 0.01
        targetSizeSlider.maximumValue = 1.0
        targetSizeSlider.value = 0.1
        targetSizeSlider.addTarget(self, action: #selector(targetSizeSliderChanged(_:)), for: [.valueChanged, .touchUpInside, .touchUpOutside])
        self.view.addSubview(targetSizeSlider)

        // Add Bubble for Target Size
        targetSizeBubble = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 25))
        targetSizeBubble.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        targetSizeBubble.textColor = .black
        targetSizeBubble.textAlignment = .center
        targetSizeBubble.font = UIFont.systemFont(ofSize: 12)
        targetSizeBubble.layer.cornerRadius = 12.5
        targetSizeBubble.layer.masksToBounds = true
        targetSizeBubble.isHidden = true
        self.view.addSubview(targetSizeBubble)

        // Add Rotation Compass
        rotationCompass = CompassView(frame: CGRect(x: self.view.frame.size.width - 120, y: self.view.frame.size.height / 2 - 35, width: 70, height: 70))
        rotationCompass.delegate = self
        self.view.addSubview(rotationCompass)

        // Add Vertical Slider for moving the object up and down
        let verticalSlider = UISlider(frame: CGRect(x: -150, y: self.view.frame.size.height - 500, width: self.view.frame.size.width - 40, height: 40))
        verticalSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        verticalSlider.minimumValue = -1 // Less sensitive
        verticalSlider.maximumValue = 1  // Less sensitive
        verticalSlider.value = 0.0
        verticalSlider.addTarget(self, action: #selector(verticalSliderChanged(_:)), for: .valueChanged)
        self.view.addSubview(verticalSlider)
        
        let saveButton = UIButton(frame: CGRect(x: 20, y: 40, width: 100, height: 50))
        saveButton.setTitle("Save Scene", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.addTarget(self, action: #selector(saveSceneButtonTapped), for: .touchUpInside)
        self.view.addSubview(saveButton)

        let loadButton = UIButton(frame: CGRect(x: 130, y: 40, width: 100, height: 50))
        loadButton.setTitle("Load Scene", for: .normal)
        loadButton.backgroundColor = .systemGreen
        loadButton.addTarget(self, action: #selector(loadSceneButtonTapped), for: .touchUpInside)
        self.view.addSubview(loadButton)
    }

    @objc func saveSceneButtonTapped() {
        guard let currentFrame = sceneView.session.currentFrame else {
            print("Failed to get current ARFrame")
            return
        }

        var modelsData: [[String: Any]] = []

        for model in models {
            let modelTransform = model.simdTransform
            let cameraTransform = currentFrame.camera.transform
            let relativeTransform = simd_mul(cameraTransform, modelTransform)

            let position = SCNVector3(relativeTransform.columns.3.x, relativeTransform.columns.3.y, relativeTransform.columns.3.z)
            let scale = model.scale
            let rotation = model.eulerAngles
            let urlString = modelURLs[model]?.lastPathComponent ?? ""

            let modelData: [String: Any] = [
                "relativePosition": ["x": position.x, "y": position.y, "z": position.z],
                "scale": ["x": scale.x, "y": scale.y, "z": scale.z],
                "rotation": ["x": rotation.x, "y": rotation.y, "z": rotation.z],
                "fileName": urlString
            ]

            modelsData.append(modelData)
        }

        let sceneDict: [String: Any] = ["models": modelsData]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sceneDict, options: .prettyPrinted)
            DocumentHandler.saveSceneFile(jsonData: jsonData, from: self)
            print("Scene saved successfully")
        } catch {
            print("Failed to save scene: \(error)")
        }
    }

    @objc func loadSceneButtonTapped() {
        DocumentHandler.presentDocumentPicker(from: self, delegate: self)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        if controller.documentPickerMode == .open {
            if url.pathExtension.lowercased() == "usdz" {
                DocumentHandler.handleDocumentPicker(urls: urls, viewController: self)
            } else if url.pathExtension.lowercased() == "json" {
                loadScene(from: url)
            } else {
                print("Unsupported file type selected")
            }
        }
    }

    func loadScene(from url: URL) {
        // Access the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let jsonData = try Data(contentsOf: url)
            if let sceneDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let modelData = sceneDict["models"] as? [[String: Any]] {
                for data in modelData {
                    guard let positionData = data["relativePosition"] as? [String: NSNumber],
                          let scaleData = data["scale"] as? [String: NSNumber],
                          let rotationData = data["rotation"] as? [String: NSNumber],
                          let fileName = data["fileName"] as? String else {
                              print("Failed to parse model data from JSON: \(data)")
                              continue
                          }

                    let position = SCNVector3(positionData["x"]!.floatValue, positionData["y"]!.floatValue, positionData["z"]!.floatValue)
                    let scale = SCNVector3(scaleData["x"]!.floatValue, scaleData["y"]!.floatValue, scaleData["z"]!.floatValue)
                    let rotation = SCNVector3(rotationData["x"]!.floatValue, rotationData["y"]!.floatValue, rotationData["z"]!.floatValue)

                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let modelURL = documentsDirectory.appendingPathComponent(fileName)

                    if let modelNode = ModelManager.loadUSDZModel(from: modelURL, sceneView: sceneView) {
                        modelNode.position = position
                        modelNode.scale = scale
                        modelNode.eulerAngles = rotation
                        models.append(modelNode)

                        // Store the URL in the dictionary
                        modelURLs[modelNode] = modelURL
                    } else {
                        print("Failed to load model from URL: \(modelURL)")
                    }
                }
            } else {
                print("Invalid JSON structure")
            }
        } catch {
            print("Failed to load scene: \(error)")
        }
    }

    func setupLighting() {
        // Create and configure a directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.castsShadow = true
        directionalLight.shadowMode = .deferred
        directionalLight.shadowSampleCount = 4
        directionalLight.shadowRadius = 10
        directionalLight.shadowColor = UIColor.black.withAlphaComponent(0.5)
        directionalLight.intensity = 1000

        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(0, 10, 10)
        directionalNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        sceneView.scene.rootNode.addChildNode(directionalNode)
    }

    @objc func uploadButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.usdz])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }

    func loadUSDZModel(from url: URL) {
        if let modelNode = ModelManager.loadUSDZModel(from: url, sceneView: sceneView) {
            models.append(modelNode)
            modelURLs[modelNode] = url // Store the URL in the dictionary
            selectedModel = modelNode

            // Position model in front of the camera
            if let position = getPositionInFrontOfCamera() {
                modelNode.position = position
            }
        }
    }

    func sanitizeVector(_ vector: SCNVector3) -> SCNVector3 {
        func isValidComponent(_ component: Float) -> Float {
            if component.isFinite {
                return component
            } else {
                print("Invalid component found: \(component)")
                return 0.0 // Default value for invalid components
            }
        }
        return SCNVector3(isValidComponent(vector.x), isValidComponent(vector.y), isValidComponent(vector.z))
    }

    @objc func targetSizeSliderChanged(_ sender: UISlider) {
        targetSize = sender.value
        targetSizeBubble.text = "\(Int(sender.value * 100))%"

        // Show bubble and update position
        targetSizeBubble.isHidden = false
        updateBubblePosition(for: sender)

        // Cancel any existing animation
        bubbleAnimator?.stopAnimation(true)

        // Fade out the bubble after a delay
        bubbleAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
            self.targetSizeBubble.alpha = 0
        }
        bubbleAnimator?.startAnimation(afterDelay: 0.6)

        if let selectedModel = selectedModel {
            ModelManager.normalizeModelSize(modelNode: selectedModel, targetSize: targetSize)
        }
        print("Target size changed to: \(targetSize)")
    }

    func updateBubblePosition(for slider: UISlider) {
        let trackRect = slider.trackRect(forBounds: slider.bounds)
        let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: trackRect, value: slider.value)
        targetSizeBubble.center = CGPoint(x: thumbRect.midX + slider.frame.minX, y: slider.frame.minY - 20)
        targetSizeBubble.alpha = 1
    }

    @objc func verticalSliderChanged(_ sender: UISlider) {
        guard let selectedModel = selectedModel else { return }
        let currentPosition = selectedModel.position
        selectedModel.position = SCNVector3(currentPosition.x, Float(sender.value), currentPosition.z)
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let location = gesture.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(location, options: [:])

            if let node = hitTestResults.first?.node {
                let rootNode = getRootNode(for: node)
                rootNode.removeFromParentNode()
                if let index = models.firstIndex(of: rootNode) {
                    models.remove(at: index)
                }
                print("Removed model: \(rootNode)")
            }
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: true])

        if let hitNode = hitTestResults.first?.node {
            selectedModel = getRootNode(for: hitNode)
            print("Selected model: \(selectedModel!)")
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let selectedModel = selectedModel else { return }

        let location = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, types: [.existingPlaneUsingExtent])

        switch gesture.state {
        case .began:
            if let result = hitTestResults.first {
                // Store the initial position when the pan gesture begins
                initialModelPosition = selectedModel.position
            }
        case .changed:
            if let result = hitTestResults.first {
                let newTransform = SCNMatrix4(result.worldTransform)
                let newPosition = SCNVector3Make(newTransform.m41, initialModelPosition?.y ?? selectedModel.position.y, newTransform.m43)

                // Update the model's position by adding the delta movement
                selectedModel.position = SCNVector3(
                    newPosition.x,
                    selectedModel.position.y, // Keep the Y position unchanged
                    newPosition.z
                )
            }
        default:
            break
        }
    }

    func getPositionInFrontOfCamera() -> SCNVector3? {
        guard let currentFrame = sceneView.session.currentFrame else {
            return nil
        }

        // Get the camera transform
        let cameraTransform = currentFrame.camera.transform

        // Convert the camera transform to a position
        let cameraPosition = SCNVector3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)

        // Set the distance in front of the camera
        let distance: Float = 0.5

        // Calculate the position in front of the camera
        let position = SCNVector3(
            cameraPosition.x + cameraTransform.columns.2.x * -distance,
            cameraPosition.y + cameraTransform.columns.2.y * -distance,
            cameraPosition.z + cameraTransform.columns.2.z * -distance
        )

        return position
    }

    // Helper method to get the root node of a selected node
    func getRootNode(for node: SCNNode) -> SCNNode {
        var rootNode = node
        while let parent = rootNode.parent, parent.name != "ModelRoot" {
            rootNode = parent
        }
        return rootNode
    }

    // ARSCNViewDelegate methods (optional, for handling AR session events)
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Handle session failure
        print("AR Session failed: \(error.localizedDescription)")
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Handle session interruption
        print("AR Session was interrupted")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("AR Session interruption ended")
        ARSessionManager.resetARSession(sceneView: sceneView)
    }

    func compassView(_ compassView: CompassView, didRotateTo angle: CGFloat) {
        guard let selectedModel = selectedModel else { return }
        selectedModel.eulerAngles.y = Float(angle)
    }
}

extension matrix_float4x4 {
    static func translation(_ t: SCNVector3) -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3.x = t.x
        matrix.columns.3.y = t.y
        matrix.columns.3.z = t.z
        return matrix
    }
}


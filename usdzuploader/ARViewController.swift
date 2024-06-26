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
    var targetSizeSlider: UISlider!
    var bubbleAnimator: UIViewPropertyAnimator?
    var rotationCompass: CompassView!
    var verticalSlider: UISlider!
    var initialModelPosition: SCNVector3?
    var inactivityTimer: Timer?
    var originalPositions: [SCNNode: SCNVector3] = [:]
    let inactivityInterval: TimeInterval = 3.0 // Time after which controls fade out
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // Ensure the view background is white
        
        // Setup ARSCNView
        sceneView = ARSCNView(frame: self.view.frame)
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true // Enable default lighting
        self.view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
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
        
        // Start the inactivity timer
        startInactivityTimer()
        
        // Add tab bar item
        self.tabBarItem = UITabBarItem(title: "AR View", image: UIImage(systemName: "arkit"), tag: 0)
    }
    
    func setupUI() {
        // Add Hamburger Menu Button
        let hamburgerButton = UIButton(type: .system)
        hamburgerButton.setTitle("☰", for: .normal)
        hamburgerButton.tintColor = .lightGray
        hamburgerButton.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        hamburgerButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hamburgerButton)
        
        // Add Slider for Target Size
        targetSizeSlider = UISlider()
        targetSizeSlider.minimumValue = 0.01
        targetSizeSlider.maximumValue = 1.0
        targetSizeSlider.value = 0.1
        targetSizeSlider.addTarget(self, action: #selector(targetSizeSliderChanged(_:)), for: [.valueChanged, .touchUpInside, .touchUpOutside])
        targetSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(targetSizeSlider)
        
        // Add Bubble for Target Size
        targetSizeBubble = UILabel()
        targetSizeBubble.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        targetSizeBubble.textColor = .black
        targetSizeBubble.textAlignment = .center
        targetSizeBubble.font = UIFont.systemFont(ofSize: 12)
        targetSizeBubble.layer.cornerRadius = 12.5
        targetSizeBubble.layer.masksToBounds = true
        targetSizeBubble.isHidden = true
        targetSizeBubble.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(targetSizeBubble)
        
        // Add Rotation Compass
        rotationCompass = CompassView()
        rotationCompass.delegate = self
        rotationCompass.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(rotationCompass)
        
        // Add Vertical Slider for moving the object up and down
        verticalSlider = UISlider()
        verticalSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        verticalSlider.minimumValue = -1 // Less sensitive
        verticalSlider.maximumValue = 1  // Less sensitive
        verticalSlider.value = 0.0
        verticalSlider.addTarget(self, action: #selector(verticalSliderChanged(_:)), for: .valueChanged)
        verticalSlider.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(verticalSlider)
        
        // Add the 'Bring Models to Center' Button
        let centerModelsButton = UIButton(type: .system)
        centerModelsButton.setImage(UIImage(systemName: "camera.metering.center.weighted"), for: .normal)
        centerModelsButton.tintColor = .lightGray
        centerModelsButton.addTarget(self, action: #selector(bringModelsToCenter), for: .touchUpInside)
        centerModelsButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(centerModelsButton)
        
        // Apply constraints
        NSLayoutConstraint.activate([
            // Hamburger Button Constraints
            hamburgerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            
            // Target Size Slider Constraints
            targetSizeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            targetSizeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            targetSizeSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            targetSizeSlider.heightAnchor.constraint(equalToConstant: 40),
            
            // Target Size Bubble Constraints
            targetSizeBubble.widthAnchor.constraint(equalToConstant: 40),
            targetSizeBubble.heightAnchor.constraint(equalToConstant: 25),
            targetSizeBubble.bottomAnchor.constraint(equalTo: targetSizeSlider.topAnchor, constant: -10),
            targetSizeBubble.centerXAnchor.constraint(equalTo: targetSizeSlider.centerXAnchor),
            
            // Rotation Compass Constraints
            rotationCompass.widthAnchor.constraint(equalToConstant: 70),
            rotationCompass.heightAnchor.constraint(equalToConstant: 70),
            rotationCompass.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            rotationCompass.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Vertical Slider Constraints
            verticalSlider.widthAnchor.constraint(equalTo: view.heightAnchor, constant: -40),
            verticalSlider.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            verticalSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Center Models Button Constraints
            centerModelsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            centerModelsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5)
        ])
    }
    
    func addGlowEffect(to node: SCNNode) {
        node.enumerateChildNodes { (child, _) in
            if child.name != "glowNode" {
                if let geometry = child.geometry {
                    let glowMaterial = SCNMaterial()
                    glowMaterial.diffuse.contents = UIColor.clear
                    glowMaterial.emission.contents = UIColor.orange
                    glowMaterial.lightingModel = .constant
                    glowMaterial.fillMode = .lines // This will give an outline effect
                    geometry.materials.append(glowMaterial)
                    child.geometry = geometry
                }
            }
        }
    }

    func removeGlowEffect(from node: SCNNode) {
        node.enumerateChildNodes { (child, _) in
            if let geometry = child.geometry {
                geometry.materials = geometry.materials.filter { $0.emission.contents as? UIColor != UIColor.orange }
                child.geometry = geometry
            }
        }
    }
    
    
    
    @objc func bringModelsToCenter() {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        // Get the camera transform
        let cameraTransform = currentFrame.camera.transform
        let cameraPosition = SCNVector3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        let distance: Float = 0.5 // Distance in front of the camera
        
        let centerPosition = SCNVector3(
            cameraPosition.x + cameraTransform.columns.2.x * -distance,
            cameraPosition.y + cameraTransform.columns.2.y * -distance,
            cameraPosition.z + cameraTransform.columns.2.z * -distance
        )
        
        originalPositions.removeAll()
        
        // Move all models to the center and add glow effect
        for model in models {
            originalPositions[model] = model.position
            
            addGlowEffect(to: model)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.2
            model.position = centerPosition
            SCNTransaction.commit()
        }
        
        // Move models back to their original positions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.moveModelsBackToOriginalPositions()
        }
    }
    
    
    func moveModelsBackToOriginalPositions() {
        for (model, originalPosition) in originalPositions {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 3.0 // Slow animation back to original positions
            model.position = originalPosition
            SCNTransaction.completionBlock = {
                self.removeGlowEffect(from: model)
            }
            SCNTransaction.commit()
        }
    }
    
    
    
    func hideControls() {
        UIView.animate(withDuration: 0.5) {
            self.targetSizeSlider.alpha = 0
            self.rotationCompass.alpha = 0
            self.verticalSlider.alpha = 0
            self.targetSizeBubble.alpha = 0
        }
    }
    
    func showControls() {
        UIView.animate(withDuration: 0.5) {
            self.targetSizeSlider.alpha = 1
            self.rotationCompass.alpha = 1
            self.verticalSlider.alpha = 1
            self.targetSizeBubble.alpha = 1
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        showControls()
        startInactivityTimer()
    }
    
    func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(timeInterval: inactivityInterval, target: self, selector: #selector(handleInactivity), userInfo: nil, repeats: false)
    }
    
    @objc func handleInactivity() {
        hideControls()
    }
    
    @objc func showMenu(_ sender: UIButton) {
        let centeredTitle: (String) -> String = { title in
            let padding = "    "
            return "\(padding)\(title)\(padding)"
        }
        
        let uploadAction = UIAction(title: centeredTitle("Upload USDZ"), image: nil) { _ in
            self.uploadButtonTapped()
        }
        let saveAction = UIAction(title: centeredTitle("Save Scene"), image: nil) { _ in
            self.saveSceneButtonTapped()
        }
        let loadAction = UIAction(title: centeredTitle("Load Scene"), image: nil) { _ in
            self.loadSceneButtonTapped()
        }
        
        let menu = UIMenu(title: "", children: [uploadAction, saveAction, loadAction])
        sender.menu = menu
        sender.showsMenuAsPrimaryAction = true
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
        let query = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal)
        let hitTestResults = sceneView.session.raycast(query!)
        
        switch gesture.state {
        case .began:
            if hitTestResults.first != nil {
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


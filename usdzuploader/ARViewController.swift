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

    //var anchorButton: UIButton!
    var centerModelsButton: UIButton!
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

    // Trash can UI elements
    var trashCanButton: UIButton!
    var trashCanImageView: UIImageView!

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

        //setup ar session
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
        hamburgerButton.tintColor = .white
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
        targetSizeSlider.addTarget(self, action: #selector(sliderTouchStarted(_:)), for: .touchDown)
        targetSizeSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside])
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
        verticalSlider.addTarget(self, action: #selector(sliderTouchStarted(_:)), for: .touchDown)
        verticalSlider.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside])
        verticalSlider.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(verticalSlider)

        // Add the 'Bring Models to Center' Button
        centerModelsButton = UIButton(type: .system)
        centerModelsButton.setImage(UIImage(systemName: "location.magnifyingglass"), for: .normal)
        centerModelsButton.tintColor = .white
        centerModelsButton.titleLabel?.font = UIFont.systemFont(ofSize: 60)
        centerModelsButton.addTarget(self, action: #selector(bringModelsToCenter), for: .touchUpInside)
        centerModelsButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(centerModelsButton)

        // Add Trash Can Button
        trashCanImageView = UIImageView(image: UIImage(systemName: "trash"))
        trashCanImageView.tintColor = .white
        trashCanImageView.contentMode = .scaleAspectFit
        trashCanImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(trashCanImageView)
        
        trashCanButton = UIButton()
        trashCanButton.translatesAutoresizingMaskIntoConstraints = false
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(trashCanLongPressed(_:)))
        longPressGesture.minimumPressDuration = 0 // Adjust the duration as needed
        trashCanButton.addGestureRecognizer(longPressGesture)
        self.view.addSubview(trashCanButton)

            /*
        anchorButton = UIButton(type: .system)
        anchorButton.setImage(UIImage(systemName: "lock.fill"), for: .normal)
        anchorButton.tintColor = .white
        anchorButton.addTarget(self, action: #selector(anchorButtonTapped), for: .touchUpInside)
        anchorButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(anchorButton)
             */
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
            rotationCompass.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 225),

            // Vertical Slider Constraints
            verticalSlider.widthAnchor.constraint(equalToConstant: 500),
            verticalSlider.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            verticalSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Center Models Button Constraints
            centerModelsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            centerModelsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            centerModelsButton.widthAnchor.constraint(equalToConstant: 40),
            centerModelsButton.heightAnchor.constraint(equalToConstant: 40),


            // Trash Can Constraints
            trashCanImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            trashCanImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            trashCanImageView.widthAnchor.constraint(equalToConstant: 30),
            trashCanImageView.heightAnchor.constraint(equalToConstant: 30),

            trashCanButton.topAnchor.constraint(equalTo: trashCanImageView.topAnchor),
            trashCanButton.bottomAnchor.constraint(equalTo: trashCanImageView.bottomAnchor),
            trashCanButton.leadingAnchor.constraint(equalTo: trashCanImageView.leadingAnchor),
            trashCanButton.trailingAnchor.constraint(equalTo: trashCanImageView.trailingAnchor),
            
            // Anchor Button Constraints
            /*
            anchorButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            anchorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            anchorButton.widthAnchor.constraint(equalToConstant: 40),
            anchorButton.heightAnchor.constraint(equalToConstant: 40)
             */
        ])
    }

    @objc func sliderTouchStarted(_ sender: UISlider) {
        // Show controls when slider is touched
        showControls()
    }

    @objc func sliderTouchEnded(_ sender: UISlider) {
        // Reset inactivity timer when slider touch ends
        startInactivityTimer()
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
        let alertController = UIAlertController(title: "Save Scene", message: "Enter a name for the scene:", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Scene Name"
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let sceneName = alertController.textFields?.first?.text, !sceneName.isEmpty else {
                print("Scene name is empty")
                return
            }
            self.saveScene(withName: sceneName)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    func saveScene(withName sceneName: String) {
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

        let sceneDict: [String: Any] = ["models": modelsData, "sceneName": sceneName]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sceneDict, options: .prettyPrinted)
            DocumentHandler.saveSceneFile(jsonData: jsonData, sceneName: sceneName, from: self)
            print("Scene saved successfully")
        } catch {
            print("Failed to save scene: \(error)")
        }
    }

    @objc func loadSceneButtonTapped() {
        let scenePicker = ScenePickerViewController { [weak self] selectedSceneURL in
            guard let self = self, let url = selectedSceneURL else { return }
            self.loadScene(from: url)
        }
        let navigationController = UINavigationController(rootViewController: scenePicker)
        present(navigationController, animated: true, completion: nil)
    }

    func loadScene(from url: URL) {
        print("Loading scene from URL: \(url)")
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

        // Show bubble and update text
        targetSizeBubble.isHidden = false
        targetSizeBubble.text = "\(Int(sender.value * 100))%"

        // If you want to hide the bubble after some time, add this code:
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.targetSizeBubble.isHidden = true
         }

        if let selectedModel = selectedModel {
            ModelManager.normalizeModelSize(modelNode: selectedModel, targetSize: targetSize)
        }
        print("Target size changed to: \(targetSize)")

        // Reset inactivity timer
        startInactivityTimer()
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

        // Reset inactivity timer
        startInactivityTimer()
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
        let results = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal)

        switch gesture.state {
        case .began:
            guard let query = results else { return }
            let hitTestResults = sceneView.session.raycast(query)
            if hitTestResults.isEmpty {
                return
            }
            let hitTestResult = hitTestResults.first!
            initialModelPosition = selectedModel.position
            updateModelPosition(selectedModel, to: hitTestResult.worldTransform)

        case .changed:
            guard let query = results else { return }
            let hitTestResults = sceneView.session.raycast(query)
            if hitTestResults.isEmpty {
                return
            }
            let hitTestResult = hitTestResults.first!
            updateModelPosition(selectedModel, to: hitTestResult.worldTransform)

        case .ended, .cancelled:
            initialModelPosition = nil

        default:
            break
        }
    }

    func updateModelPosition(_ model: SCNNode, to transform: simd_float4x4) {
        let newPosition = SCNVector3(
            transform.columns.3.x,
            initialModelPosition?.y ?? model.position.y,
            transform.columns.3.z
        )
        model.position = newPosition
    }


    func deleteModel(_ model: SCNNode) {
        model.removeFromParentNode()
        if let index = models.firstIndex(of: model) {
            models.remove(at: index)
        }
        print("Model deleted: \(model)")
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

    @objc func trashCanLongPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let alert = UIAlertController(title: "Delete All Models?", message: "Are you sure you want to delete all models?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
                self.deleteAllModels()
            }
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alert.addAction(yesAction)
            alert.addAction(noAction)
            present(alert, animated: true, completion: nil)
        }
    }


    func deleteAllModels() {
        for model in models {
            model.removeFromParentNode()
        }
        models.removeAll()
        print("All models deleted")
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
    /*
    
    @objc func anchorButtonTapped() {
        guard let selectedModel = selectedModel else {
            print("No model selected")
            return
        }

        // Log the current state of the selected model
        print("Current model transform: \(selectedModel.simdTransform)")
        print("Current model position: \(selectedModel.position)")
        print("Current model scale: \(selectedModel.scale)")

        // Normalize the model's size before anchoring
        ModelManager.normalizeModelSize(modelNode: selectedModel, targetSize: targetSize)

        let modelTransform = selectedModel.simdTransform
        let anchor = ARAnchor(transform: modelTransform)
        
        print("Anchoring model with transform: \(modelTransform)")
        
        // Remove the model from the scene's root node
        selectedModel.removeFromParentNode()
        print("Model removed from root node")

        // The model should be added to the anchor node in renderer(didAdd:for:) method
        self.selectedModel = selectedModel

        // Reset the AR session to re-detect planes
        sceneView.session.pause()
        ARSessionManager.resetARSession(sceneView: sceneView)
        
        // Add the anchor to the AR session after resetting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sceneView.session.add(anchor: anchor)
            print("Model anchored at position: \(SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z))")
        }
    }


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let selectedModel = self.selectedModel {
            print("Adding selected model to anchor node")
            node.addChildNode(selectedModel)
            
            // Logging the state of the node
            print("Node position after adding model: \(node.position)")
            print("Node scale after adding model: \(node.scale)")
            print("Node rotation after adding model: \(node.eulerAngles)")
            
            self.selectedModel = nil // Reset the selected model after anchoring
        } else {
            print("No selected model to add to anchor")
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let modelNode = node.childNodes.first else {
            //print("No child nodes found for update")
            return
        }
        
        let modelTransform = anchor.transform
        modelNode.simdTransform = modelTransform
        
        print("Updated model node with new transform: \(modelTransform)")
        
        // Logging the state of the node
        print("Node position after update: \(modelNode.position)")
        print("Node scale after update: \(modelNode.scale)")
        print("Node rotation after update: \(modelNode.eulerAngles)")
    }
*/

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

//
//  ScenePickerViewController.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 7/1/24.
//

import UIKit

class ScenePickerViewController: UITableViewController {
    private let fileManager = FileManager.default
    private let scenes: [URL]
    private let onSceneSelected: (URL?) -> Void

    init(onSceneSelected: @escaping (URL?) -> Void) {
        self.onSceneSelected = onSceneSelected
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.scenes = (try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }) ?? []
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Scene"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SceneCell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCell", for: indexPath)
        let sceneURL = scenes[indexPath.row]
        cell.textLabel?.text = sceneURL.deletingPathExtension().lastPathComponent
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSceneURL = scenes[indexPath.row]
        dismiss(animated: true) {
            self.onSceneSelected(selectedSceneURL)
        }
    }
}

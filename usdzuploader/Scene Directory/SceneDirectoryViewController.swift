//
//  SceneDirectoryViewController.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 7/1/24.
//

import UIKit
import SwiftUI

class SceneDirectoryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneDirectoryView = UIHostingController(rootView: SceneDirectoryView())
        addChild(sceneDirectoryView)
        view.addSubview(sceneDirectoryView.view)
        sceneDirectoryView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sceneDirectoryView.view.topAnchor.constraint(equalTo: view.topAnchor),
            sceneDirectoryView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneDirectoryView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneDirectoryView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        sceneDirectoryView.didMove(toParent: self)
    }
}


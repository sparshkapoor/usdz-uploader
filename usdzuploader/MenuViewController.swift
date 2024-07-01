//
//  MenuViewController.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/26/24.
//

import UIKit
import SwiftUI

class MenuViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let modelDirectoryView = UIHostingController(rootView: ModelDirectoryView())
        addChild(modelDirectoryView)
        view.addSubview(modelDirectoryView.view)
        modelDirectoryView.didMove(toParent: self)
        
        modelDirectoryView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modelDirectoryView.view.topAnchor.constraint(equalTo: view.topAnchor),
            modelDirectoryView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            modelDirectoryView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modelDirectoryView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}






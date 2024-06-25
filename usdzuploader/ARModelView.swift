//
//  ARModelView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/19/24.
//

import SwiftUI
import ARKit

struct ARModelView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

//
//  MenuController.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/26/24.
//

import UIKit
import SwiftUI

class MenuController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default is AR View
        self.selectedIndex = 1
        
        // Set the custom tab bar
        let customTabBar = CustomTabBar()
        setValue(customTabBar, forKey: "tabBar")
        
        // Customize the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.backgroundColor = .separator
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.blue]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Apply the appearance settings
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // Add a small border to the top of the tab bar
        addTopBorder(to: tabBar, color: .lightGray, borderWidth: 0.5)

        // Initialize view controllers
        let arViewController = ARViewController()
        let whiteScreenViewController = MenuViewController()

        // Configure tab bar items
        let arTabBarItem = UITabBarItem(title: "AR View", image: UIImage(systemName: "arkit"), tag: 0)
        arTabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2) // Move text down
        arTabBarItem.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0) // Move icon down
        arViewController.tabBarItem = arTabBarItem
        
        let whiteScreenTabBarItem = UITabBarItem(title: "White Screen", image: UIImage(systemName: "square.fill"), tag: 1)
        whiteScreenTabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2) // Adjust if needed
        whiteScreenTabBarItem.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0) // Adjust if needed
        whiteScreenViewController.tabBarItem = whiteScreenTabBarItem

        // Add view controllers to the tab bar
        self.viewControllers = [arViewController, whiteScreenViewController]
        
        // Ensure the view controllers' view extends under the status bar and tab bar
        arViewController.edgesForExtendedLayout = [.top, .bottom]
        whiteScreenViewController.edgesForExtendedLayout = [.top, .bottom]
    }

    private func addTopBorder(to view: UIView, color: UIColor, borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: view.topAnchor),
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: borderWidth)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the tab bar extends to the full width of the screen
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            var tabBarFrame = tabBar.frame
            tabBarFrame.size.width = window.bounds.width
            tabBarFrame.origin.x = 0
            tabBar.frame = tabBarFrame
        }
    }
}

struct TabBarControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITabBarController {
        return MenuController()
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}

struct MenuPreview: PreviewProvider {
    static var previews: some View {
        TabBarControllerRepresentable()
    }
}



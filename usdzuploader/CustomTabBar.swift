//
//  CustomTabBar.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/26/24.
//

import UIKit

class CustomTabBar: UITabBar {
    private var customItems: [UITabBarItem] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttons = subviews.filter { $0 is UIControl }
        let itemCount = CGFloat(buttons.count)
        let buttonWidth = bounds.width / itemCount
        var buttonHeight = bounds.height
        if UIDevice.current.orientation.isPortrait {
            buttonHeight -= 25
        }
        else {
            buttonHeight -= 18
        }
        
        
        for (index, button) in buttons.enumerated() {
            let xPosition = buttonWidth * CGFloat(index)
            button.frame = CGRect(x: xPosition, y: 0, width: buttonWidth, height: buttonHeight)
        }
    }
}



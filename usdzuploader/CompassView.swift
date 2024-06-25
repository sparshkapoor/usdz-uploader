//
//  CompassView.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/19/24.
//

import UIKit

protocol CompassViewDelegate: AnyObject {
    func compassView(_ compassView: CompassView, didRotateTo angle: CGFloat)
}

class CompassView: UIView {
    
    weak var delegate: CompassViewDelegate?
    private var rotationAngle: CGFloat = 0
    
    private let knob: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        layer.cornerRadius = frame.size.width / 2
        
        addSubview(knob)
        
        knob.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        knob.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20).isActive = true
        knob.widthAnchor.constraint(equalToConstant: 30).isActive = true
        knob.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let angle = atan2(location.y - bounds.midY, location.x - bounds.midX)
        rotationAngle = angle
        
        // Rotate knob smoothly
        UIView.animate(withDuration: 0.1) {
            self.knob.center = CGPoint(x: self.bounds.midX + cos(self.rotationAngle) * (self.bounds.width / 2 - 20),
                                       y: self.bounds.midY + sin(self.rotationAngle) * (self.bounds.height / 2 - 20))
            self.knob.transform = CGAffineTransform(rotationAngle: self.rotationAngle)
        }
        
        // Notify delegate
        delegate?.compassView(self, didRotateTo: rotationAngle)
    }
}


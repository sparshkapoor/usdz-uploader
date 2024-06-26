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
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        layer.cornerRadius = frame.size.width / 2
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(knob)
        
        NSLayoutConstraint.activate([
            knob.widthAnchor.constraint(equalToConstant: 30),
            knob.heightAnchor.constraint(equalToConstant: 30),
            knob.centerXAnchor.constraint(equalTo: centerXAnchor),
            knob.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10)
        ])
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.width / 2
        updateKnobPosition()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let angle = atan2(location.y - bounds.midY, location.x - bounds.midX)
        rotationAngle = angle
        
        // Rotate knob smoothly
        UIView.animate(withDuration: 0.1) {
            self.updateKnobPosition()
            self.knob.transform = CGAffineTransform(rotationAngle: self.rotationAngle)
        }
        
        // Notify delegate
        delegate?.compassView(self, didRotateTo: rotationAngle)
    }
    
    private func updateKnobPosition() {
        knob.center = CGPoint(x: bounds.midX + cos(rotationAngle) * (bounds.width / 2 - 20),
                              y: bounds.midY + sin(rotationAngle) * (bounds.height / 2 - 20))
    }
}

// Usage in a ViewController
class ViewController: UIViewController, CompassViewDelegate {
    
    private let compassView = CompassView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        compassView.delegate = self
        view.addSubview(compassView)
        
        // Auto Layout constraints for compassView
        NSLayoutConstraint.activate([
            compassView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            compassView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            compassView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            compassView.heightAnchor.constraint(equalTo: compassView.widthAnchor)
        ])
    }
    
    func compassView(_ compassView: CompassView, didRotateTo angle: CGFloat) {
        print("Compass rotated to angle: \(angle)")
    }
}



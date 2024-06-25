//
//  SCNNode+Extension.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/21/24.
//

import ARKit
import ObjectiveC

private var modelURLKey: UInt8 = 0

extension SCNNode {
    var modelURL: URL? {
        get {
            return objc_getAssociatedObject(self, &modelURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(self, &modelURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

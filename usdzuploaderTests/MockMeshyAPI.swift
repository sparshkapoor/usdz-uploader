//
//  MockMeshyAPI.swift
//  usdzuploaderTests
//
//  Created by WorkMerkDev on 6/28/24.
//

import Foundation

class MockMeshyAPI: MeshyAPITest {
    var shouldFail: Bool
    var completionDelay: TimeInterval

    init(shouldFail: Bool = false, completionDelay: TimeInterval = 1.0) {
        self.shouldFail = shouldFail
        self.completionDelay = completionDelay
    }

    override func generate3DModel(from prompt: String, progressUpdate: @escaping (Double) -> Void, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + completionDelay) {
            if self.shouldFail {
                completion(nil)
            } else {
                let mockURL = URL(string: "https://example.com/model.usdz")!
                completion(mockURL)
            }
        }
    }
}





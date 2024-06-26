//
//  usdzuploaderApp.swift
//  usdzuploader
//
//  Created by WorkMerkDev on 6/19/24.
//

import SwiftUI

@main
struct usdzuploaderApp: App {
    var body: some Scene {
        WindowGroup {
            TabBarControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
            
        }
    }
}

struct ContentViewPreview: PreviewProvider {
    static var previews: some View {
        TabBarControllerRepresentable()
        .edgesIgnoringSafeArea(.all)
    }
}

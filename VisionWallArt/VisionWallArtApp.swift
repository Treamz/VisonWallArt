//
//  VisionWallArtApp.swift
//  VisionWallArt
//
//  Created by Иван Чернокнижников on 13.03.2024.
//

import SwiftUI

@main
struct VisionWallArtApp: App {
    
    @State private var viewModel = ViewModel()
    
    init() {
        ImpactParticleSystem.registerSystem()
        ProjectileComponent.registerComponent()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(viewModel) 
        }
        
        WindowGroup(id: "doodle_canvas") {
            DoodleView()
                .environment(viewModel)
        }
    }
}

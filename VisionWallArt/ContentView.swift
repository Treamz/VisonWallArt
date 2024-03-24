//
//  ContentView.swift
//  VisionWallArt
//
//  Created by Иван Чернокнижников on 13.03.2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack(alignment: .leading, content: {
            Text("Welcom to Vision Wall Art")
                .font(.extraLargeTitle2)
        })
        .padding(40)
        .glassBackgroundEffect()
        .onAppear {
            Task {
                await openImmersiveSpace(id: "ImmersiveSpace")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}

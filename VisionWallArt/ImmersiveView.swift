//
//  ImmersiveView.swift
//  VisionWallArt
//
//  Created by Иван Чернокнижников on 13.03.2024.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

struct ImmersiveView: View {
    
    @Environment(ViewModel.self) private var viewModel
    
    @Environment(\.openWindow) private var openWindow
    @State private var inputText = ""
    @State public var showTextField = false
    
    @State var characterEntity: Entity = {
        let headAnchor = AnchorEntity(.head)
        headAnchor.position = [0.7,-0.35,-1]
        let radians = -30 * Float.pi / 180
        ImmersiveView.rotateEntityAroundYAxis(entity: headAnchor, angle: radians)
        return headAnchor
    }()
    
    @State private var projectile: Entity? = nil

    @State private var assistant: Entity? = nil
    @State private var waveAnimation: AnimationResource? = nil
    @State private var jumpAnimation: AnimationResource? = nil

    @State public var showAttachmentButtons = false
    let tapSubject = PassthroughSubject<Void,Never>()
    
    @State var cancallabe: Cancellable?

    @State var planeEntity: Entity = {
        let wallAnchor = AnchorEntity(.plane(.vertical, classification: .wall, minimumBounds: SIMD2<Float>(0.6,0.6)))
        let planeMesh = MeshResource.generatePlane(width: 2.25, depth: 1.625,cornerRadius: 0.1)
        let material = ImmersiveView.loadImageMaterial(imageUrl: "think_different")
        
        let planeEntity = ModelEntity(mesh: planeMesh,materials: [material])
        
        planeEntity.name = "canvas"
        
        wallAnchor.addChild(planeEntity)
        
        return wallAnchor
    }()
    
    var body: some View {
        RealityView { content, attachments in
            // Add the initial RealityKit content
            do {
                let immersiveEntity = try await Entity(named: "Immersive", in: realityKitContentBundle)
                characterEntity.addChild(immersiveEntity)
                content.add(characterEntity)
                content.add(planeEntity)
                guard let attachmentEntity = attachments.entity(for: "attachment") else {return }
                attachmentEntity.position = SIMD3<Float>(0,0.62,0)
                let radians = 30 * Float.pi / 180
                ImmersiveView.rotateEntityAroundYAxis(entity: attachmentEntity, angle: radians)
                characterEntity.addChild(attachmentEntity)
                
                // identify assistant + applying basic animation
                
                let characterAnimationSceneEntity = try await Entity(named: "CharacterAnimations",in: realityKitContentBundle)
                
                guard let waveModel = characterAnimationSceneEntity.findEntity(named: "wave_model") else {return}
                
                guard let assistant = characterEntity.findEntity(named: "assistant") else {return}
                
                
                /// JUMP
                guard let jumpUpModel = characterAnimationSceneEntity.findEntity(named: "jump_up_model") else {return}
                
                guard let jumpFloatModel = characterAnimationSceneEntity.findEntity(named: "jump_float_model") else {return}
                
                guard let jumpDownModel = characterAnimationSceneEntity.findEntity(named: "jump_down_model") else {return}
                
                guard let idleAnimationResource = assistant.availableAnimations.first else {return }
                
                guard let waveAnimationResource = waveModel.availableAnimations.first else {return }
                
                let projectileSceneEntity = try await Entity(named: "MainParticle",in: realityKitContentBundle)
                
                guard let projecttile = projectileSceneEntity.findEntity(named: "ParticleRoot") else {return}
                
                projecttile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = false
                projecttile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = false
                projecttile.components.set(ProjectileComponent())
                characterEntity.addChild(projecttile)
                
                
                // Impact Particle
                
                let impactParticleSceneEntity = try await Entity(named: "ImpactParticle",in: realityKitContentBundle)
                
                guard let impactParticle = impactParticleSceneEntity.findEntity(named: "ImpactParticle") else {return}
                
                impactParticle.position = [0,0,0]
                
                impactParticle.components[ParticleEmitterComponent.self]?.burstCount = 500
                impactParticle.components[ParticleEmitterComponent.self]?.emitterShapeSize.x = 3.75 / 2
                impactParticle.components[ParticleEmitterComponent.self]?.emitterShapeSize.y = 2.625 / 2
                
                
                planeEntity.addChild(impactParticle)

                let waveAnimation = try AnimationResource.sequence(with: [waveAnimationResource,idleAnimationResource.repeat()])
                
                assistant.playAnimation(idleAnimationResource.repeat())
                
                
                guard let jumpUpAnimationResource = jumpUpModel.availableAnimations.first else {return}
                guard let jumpFloatAnimationResource = jumpFloatModel.availableAnimations.first else {return}
                guard let jumpDownAnimationResource = jumpDownModel.availableAnimations.first else {return}

                let jumpAnimation = try AnimationResource.sequence(with: [jumpUpAnimationResource,jumpFloatAnimationResource,jumpDownAnimationResource,idleAnimationResource.repeat()])
                Task {
                    self.assistant = assistant
                    self.waveAnimation = waveAnimation
                    self.jumpAnimation = jumpAnimation
                    self.projectile = projecttile
                }
            }
            catch {
                print("Error in RealityView`s male \(error)")
            }
        } attachments: {
            Attachment(id: "attachment") {
                VStack {
                    Text(inputText)
                        .frame(maxWidth: 400,alignment: .leading)
                        .font(.extraLargeTitle2)
                        .fontWeight(.regular)
                        .padding(40)
                        .glassBackgroundEffect()
                    
                    if showAttachmentButtons {
                        HStack(spacing: 20) {
                            Button {
                                tapSubject.send()
                            } label: {
                                Text("Yes, Let`s go!")
                                    .font(.largeTitle)
                                    .fontWeight(.regular)
                                    .padding()
                            }
                            .padding()
                            .buttonStyle(.bordered)
                            
                            Button {
                               //
                            } label: {
                                Text("No")
                                    .font(.largeTitle)
                                    .fontWeight(.regular)
                                    .padding()
                            }
                            .padding()
                            .buttonStyle(.bordered)

                        }
                        .glassBackgroundEffect()
                        .opacity(showAttachmentButtons ? 1:0)
                    }
                }
                .opacity(showTextField ? 1 :  0)

            }
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded({ _ in
            viewModel.flowState = .intro
        }))
        .onChange(of: viewModel.flowState) { oldValue, newValue in
            switch newValue {
                
            case .idle:
                break
            case .intro:
                playIntroSequence()
                
            case .projectingFlying:
                if let projectile = self.projectile {
                    // hardcode the destination where the particle is going to move
                    // so that it always traverse towards the center of the simulator screeen
                    // the reason we do that is because we can't get the real transform of the anchor entity
                    let dest = Transform(scale: projectile.transform.scale, rotation: projectile.transform.rotation,translation: [-0.7, 0.15, -0.5] * 2)
                    Task {
                        let duration = 3.0
                        projectile.position = [0, 0.1, 0]
                        projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = true
                        projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = true
                        projectile.move(to: dest, relativeTo: self.characterEntity, duration: duration, timingFunction: .easeInOut)
                        try? await Task.sleep(for: .seconds(duration))
                        projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = false
                        projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = false
                        viewModel.flowState = .updateWallArt
                    }
                }
                break
            case .updateWallArt:
                
                // somehow a system can't seem to access viewModel
                // so here we update one of its static variable instead
                self.projectile?.components[ProjectileComponent.self]?.canBurst = true

                if let plane = planeEntity.findEntity(named: "canvas") as? ModelEntity {
                                    plane.model?.materials = [ImmersiveView.loadImageMaterial(imageUrl: "sketch")]
                }
                
                if let assistant = self.assistant, let jumpAnimation = self.jumpAnimation {
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        assistant.playAnimation(jumpAnimation)
                        await animatePromptText(text: "Awesome!")
                        try? await Task.sleep(for: .milliseconds(500))
                        await animatePromptText(text: "What else do you want to see us\n build in Vision Pro?")

                    }
                }
                break
            }
        }
    }
    
    static func rotateEntityAroundYAxis(entity: Entity, angle: Float) {
        // Get the current transform of the entity
        var currentTransform = entity.transform
        
        // Create a quatertnion representing a rotation around the Y-axis
        let rotation  = simd_quatf(angle: angle, axis: [0,1,0])
        
        // Combine the rotation with current transform
        currentTransform.rotation = rotation * currentTransform.rotation
        
        entity.transform = currentTransform
        
    }
    
    
    static func loadImageMaterial(imageUrl: String) -> SimpleMaterial {
        do {
            let texture = try TextureResource.load(named: imageUrl)
            var material = SimpleMaterial()
            
            let color = SimpleMaterial.BaseColor(texture: MaterialParameters.Texture(texture))
            
            material.color = color
            return material
            
        }
        catch {
            fatalError(String(describing: error))
        }
        
    }
    
    func waitForButtonTap(using buttonTapPubisher: PassthroughSubject<Void,Never>) async {
        
        await withCheckedContinuation {continuation in
            let cancellable = tapSubject.first().sink { _ in
                continuation.resume()
            }
            self.cancallabe = cancellable
            
        }
    }
    
    func animatePromptText(text: String) async {
        inputText = ""
        let words = text.split(separator: " ")
        for word in words {
            inputText.append(word + " ")
            let milliseconds = (1 + UInt64.random(in: 0...1)) * 100
            try? await Task.sleep(for:.milliseconds(milliseconds))
        }
    }
    
    func playIntroSequence() {
        print("playIntroSequence")
        Task {
            if !showTextField {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTextField.toggle()
                }
            }
            if let assistant = self.assistant, let waveAnimation = self.waveAnimation {
                await assistant.playAnimation(waveAnimation.repeat(count: 1))
            }
            
            let texts = [
                "Hey :) Let's create some doodle art with the Vision Pro. Are you ready?\n",
                "Awesome. Draw something and\n watch it come alive."
            ]
            
            await animatePromptText(text: texts[0])
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showAttachmentButtons = true
            }
            
            await waitForButtonTap(using: tapSubject)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showAttachmentButtons = false
            }
            
            Task {
                await animatePromptText(text: texts[1])
            }
            
            DispatchQueue.main.async {
                openWindow(id: "doodle_canvas")
            }
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}

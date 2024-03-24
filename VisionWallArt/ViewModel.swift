//
//  ViewModel.swift
//  VisionWallArt
//
//  Created by Иван Чернокнижников on 13.03.2024.
//

import Foundation
import Observation
enum FlowState {
    case idle, intro, projectingFlying, updateWallArt
    
}

@Observable
class ViewModel {
    var flowState = FlowState.idle
}

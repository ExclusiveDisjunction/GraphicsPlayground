//
//  CameraController.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/30/25.
//

import SwiftUI
import simd;

@Observable
class CameraController {
    init(loc: SIMD3<Float> = SIMD3<Float>(0, 0, -5), rot: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        self.position = loc;
        self.rotation = rot;
    }
    
    var position: SIMD3<Float>;
    var rotation: SIMD3<Float>;
    
    var cameraMatrix: float4x4 {
        let rotation = float4x4(rotation: rotation);
        let loc = float4x4(translation: position);
        
        return rotation * loc;
    }
}

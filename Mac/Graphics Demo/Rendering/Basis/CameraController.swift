//
//  CameraController.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/30/25.
//

import SwiftUI
import simd;

extension float4x4 {
    init(lookAt eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) {
        let f = normalize(center - eye)           // forward
        let s = normalize(cross(f, up))           // right
        let u = cross(s, f)                       // recalculated up
        
        let m = float4x4(
            SIMD4<Float>( s.x,  u.x, -f.x, 0),
            SIMD4<Float>( s.y,  u.y, -f.y, 0),
            SIMD4<Float>( s.z,  u.z, -f.z, 0),
            SIMD4<Float>(-dot(s, eye), -dot(u, eye), dot(f, eye), 1)
        )
        
        self = m
    }
}

@Observable
class CameraController {
    init(eye: SIMD3<Float> = .init(2, 2, 2), center: SIMD3<Float> = .init(0, 0, 0), up: SIMD3<Float> = .init(0, 1, 0)) {
        self.eye = eye
        self.center = center
        self.up = up
    }
    
    var eye: SIMD3<Float>;
    var center: SIMD3<Float>;
    var up: SIMD3<Float>;
    
    var forward: SIMD3<Float> {
        normalize(center - eye)
    }
    var reverse: SIMD3<Float> {
        -forward
    }
    var right: SIMD3<Float> {
        normalize(cross(forward, up))
    }
    var left: SIMD3<Float> {
        -right
    }
    var cameraUp: SIMD3<Float> {
        cross(right, forward)
    }
    
    var cameraMatrix: float4x4 {
        .init(lookAt: eye, center: center, up: up)
    }
}

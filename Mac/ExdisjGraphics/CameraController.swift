//
//  CameraController.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/30/25.
//

import SwiftUI
import simd;

public extension float4x4 {
    /// Constructs a matrix from a  "look at" setup.
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

/// Represents a UI compatible association of data that can be used to control a camera.
/// This uses the "look at" approach.
@Observable
public class CameraController {
    /// Creates the controller with specific values.
    /// - Parameters:
    ///     - eye: The camera's location
    ///     - center: Where the camera is looking at
    ///     - up: The camera's sense of up
    public init(eye: SIMD3<Float> = .init(2, 2, 2), center: SIMD3<Float> = .init(0, 0, 0), up: SIMD3<Float> = .init(0, 1, 0)) {
        self.eye = eye
        self.center = center
        self.up = up
    }
    
    /// The camera's location
    public var eye: SIMD3<Float>;
    /// Where the camera is looking at
    public var center: SIMD3<Float>;
    //// The camera's sense of up
    public var up: SIMD3<Float>;
    
    /// The forward direction. This is from `eye`, and towards `center`.
    public var forward: SIMD3<Float> {
        normalize(center - eye)
    }
    /// The backwards direction. This is from `eye`, and away from `center`.
    public var reverse: SIMD3<Float> {
        -forward
    }
    /// The right direction. This is the tangent of  `forward`.
    public var right: SIMD3<Float> {
        normalize(cross(forward, up))
    }
    /// The left direction. This is the negative of `forward`.
    public var left: SIMD3<Float> {
        -right
    }
    ///. The transformed up value for the camera. This is the cross of `right` and `forward`.
    public var cameraUp: SIMD3<Float> {
        cross(right, forward)
    }
    
    /// Computes the final camera matrix based on the `eye`, `center`, and `up`.
    public var cameraMatrix: float4x4 {
        .init(lookAt: eye, center: center, up: up)
    }
}

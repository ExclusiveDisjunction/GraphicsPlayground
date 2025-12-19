//
//  Transform.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 6/2/25.
//

import SwiftUI
import simd;

public extension float4x4 {
    /// Computes the matrix needed for representing translations.
    init(translation t: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(t, 1)
    }
    
    /// Computes the matrix needed to represent scaling each dimension by the factors provided in `scaling`.
    init(scaling s: SIMD3<Float>) {
        self.init(SIMD4<Float>(s.x, 0,   0,   0),
                  SIMD4<Float>(0,   s.y, 0,   0),
                  SIMD4<Float>(0,   0,   s.z, 0),
                  SIMD4<Float>(0,   0,   0,   1))
    }
    
    /// Computes the matrix needed to represent the rotation of an object, using the angles provided by `rotation`. Note that this assumes radian angles.
    init(rotation angles: SIMD3<Float>) {
        let rx = float4x4(rotationX: angles.x)
        let ry = float4x4(rotationY: angles.y)
        let rz = float4x4(rotationZ: angles.z)
        self = rz * ry * rx // typical rotation order
    }
    
    /// Computes the matrix for rotating in the X direction. This assumes radian angles.
    init(rotationX angle: Float) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, cos(angle), -sin(angle), 0),
                  SIMD4<Float>(0, sin(angle), cos(angle), 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    /// Computes the matrix for rotating in the Y direction. This assumes radian angles.
    init(rotationY angle: Float) {
        self.init(SIMD4<Float>(cos(angle), 0, sin(angle), 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(-sin(angle), 0, cos(angle), 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    /// Computes the matrix for rotating in the Z direction. This assumes radian angles.
    init(rotationZ angle: Float) {
        self.init(SIMD4<Float>(cos(angle), -sin(angle), 0, 0),
                  SIMD4<Float>(sin(angle), cos(angle), 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    /// Computes the matrix needed for a perspective matrix.
    init(perspectiveFov fovY: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let y = 1 / tan(fovY * 0.5)
        let x = y / aspectRatio
        let z = farZ / (nearZ - farZ)
        
        self.init(SIMD4<Float>( x,  0,  0,   0),
                  SIMD4<Float>( 0,  y,  0,   0),
                  SIMD4<Float>( 0,  0,  z,  -1),
                  SIMD4<Float>( 0,  0,  z * nearZ,  0))
    }
}


/// Represents a UI integratable type that stores a model's transformations.
/// This allows for position, rotation, and scale transformations.
@Observable
public class StandardTransformations {
    /// Creates the transformations with specific values. By default, the position is the origin, no rotation, and the scale in 1 in each direction.
    public init(position: SIMD3<Float> = SIMD3<Float>(0, 0, 0), rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0), scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
    
    /// The current position for the mesh
    public var position: SIMD3<Float>;
    /// The current rotation for the mesh. This is in radians
    public var rotation: SIMD3<Float>;
    public var rotationDeg : SIMD3<Float> {
        get {
            self.rotation * (180 / .pi)
        }
        set {
            self.rotation = newValue * (.pi / 180)
        }
    }
    /// The current scale for the mesh.
    public var scale: SIMD3<Float>;
    
    /// The current matrix encoding the position, rotation, and scale. This can be used to represent the transformation that each vertex will go through.
    public var modelMatrix : float4x4 {
        let transformationMatrix = float4x4(translation: position);
        let rotationMatrix = float4x4(rotation: rotation);
        let scaleMatrix = float4x4(scaling: scale)
        
        return transformationMatrix * rotationMatrix * scaleMatrix;
    }
}

/// A simple wrapper that encodes a transformation, using `StandardTransformations`. This can be used as an instance manager.
public struct MeshInstance : Identifiable {
    public init(trans: StandardTransformations = StandardTransformations(), id: UUID = UUID()) {
        self.transform = trans
        self.id = id
    }
    
    public var transform: StandardTransformations
    public var id: UUID;
}

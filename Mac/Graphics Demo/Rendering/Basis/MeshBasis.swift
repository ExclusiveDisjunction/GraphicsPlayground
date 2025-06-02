//
//  MeshBasics.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import simd
import Metal

extension float4x4 {
    init(translation t: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(t, 1)
    }
    
    init(scaling s: SIMD3<Float>) {
        self.init(SIMD4<Float>(s.x, 0,   0,   0),
                  SIMD4<Float>(0,   s.y, 0,   0),
                  SIMD4<Float>(0,   0,   s.z, 0),
                  SIMD4<Float>(0,   0,   0,   1))
    }
    
    init(rotation angles: SIMD3<Float>) {
        let rx = float4x4(rotationX: angles.x)
        let ry = float4x4(rotationY: angles.y)
        let rz = float4x4(rotationZ: angles.z)
        self = rz * ry * rx // typical rotation order
    }
    
    init(rotationX angle: Float) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, cos(angle), -sin(angle), 0),
                  SIMD4<Float>(0, sin(angle), cos(angle), 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    init(rotationY angle: Float) {
        self.init(SIMD4<Float>(cos(angle), 0, sin(angle), 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(-sin(angle), 0, cos(angle), 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    init(rotationZ angle: Float) {
        self.init(SIMD4<Float>(cos(angle), -sin(angle), 0, 0),
                  SIMD4<Float>(sin(angle), cos(angle), 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
}

struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD3<Float>
}

/// A protocol representing an object to display.
/// A mesh is like a template, it can be used over and over. It has some internal dimensions, but this gets transformed & represented on the screen.
protocol MeshBasis {
    /// A unique name used to identify the specific mesh.
    static var name: String { get }
    /// The buffer for the meshes' vertices.
    var buffer: MTLBuffer { get }
    /// The number of items stored in the buffer.
    var count: Int { get }
}
/// Represents a mesh that has vertices, and uses indexes to hold the valuesl
protocol IndexBasedMesh : MeshBasis {
    var indexBuffer: MTLBuffer { get }
    var indexCount: Int { get }
}

protocol PrimativeMesh : MeshBasis {
    init(_ device: MTLDevice) throws(MissingMetalComponentError);
    
    static func generateVertices() -> [Vertex]
}
protocol IndexBasedPrimativeMesh : PrimativeMesh, IndexBasedMesh {
    
}

@Observable
class StandardTransformations {
    init(position: SIMD3<Float> = SIMD3<Float>(0, 0, 0), rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0), scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
    
    var position: SIMD3<Float>;
    var rotation: SIMD3<Float>;
    var scale: SIMD3<Float>;
    
    var modelMatrix : float4x4 {
        let transformationMatrix = float4x4(translation: position);
        let rotationMatrix = float4x4(rotation: rotation);
        let scaleMatrix = float4x4(scaling: scale)
        
        return transformationMatrix * rotationMatrix * scaleMatrix;
    }
}

struct MeshInstance : Identifiable {
    init(trans: StandardTransformations = StandardTransformations(), id: UUID = UUID()) {
        self.transform = trans
        self.id = id
    }
    
    var transform: StandardTransformations
    var id: UUID;
}

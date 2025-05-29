//
//  CubeMesh.swift
//  Graphics Demo
//
//  Created by Hollan on 5/29/25.
//

import MetalKit
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

class CubeMesh  {
    var vertexBuffer: MTLBuffer
    var vertexCount: Int;
    
    init?(device: MTLDevice) {
        let vertices: [Vertex] = CubeMesh.generateCubeVertices()
        self.vertexCount = vertices.count
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: []) else {
            return nil;
        }
        
        self.vertexBuffer = vertexBuffer
    }
    
    static func generateCubeVertices() -> [Vertex] {
        let r = SIMD3<Float>(1, 0, 0)
        let g = SIMD3<Float>(0, 1, 0)
        let b = SIMD3<Float>(0, 0, 1)
        let y = SIMD3<Float>(1, 1, 0)
        let c = SIMD3<Float>(0, 1, 1)
        let m = SIMD3<Float>(1, 0, 1)
        
        let p: (Float, Float, Float) -> SIMD3<Float> = { x, y, z in SIMD3(x, y, z) }
        
        return [
            // Front (+Z, blue)
            Vertex(position: p(-0.5, -0.5,  0.5), color: b),
            Vertex(position: p( 0.5, -0.5,  0.5), color: b),
            Vertex(position: p( 0.5,  0.5,  0.5), color: b),
            Vertex(position: p(-0.5, -0.5,  0.5), color: b),
            Vertex(position: p( 0.5,  0.5,  0.5), color: b),
            Vertex(position: p(-0.5,  0.5,  0.5), color: b),
            
            // Back (-Z, green)
            Vertex(position: p( 0.5, -0.5, -0.5), color: g),
            Vertex(position: p(-0.5, -0.5, -0.5), color: g),
            Vertex(position: p(-0.5,  0.5, -0.5), color: g),
            Vertex(position: p( 0.5, -0.5, -0.5), color: g),
            Vertex(position: p(-0.5,  0.5, -0.5), color: g),
            Vertex(position: p( 0.5,  0.5, -0.5), color: g),
            
            // Left (-X, red)
            Vertex(position: p(-0.5, -0.5, -0.5), color: r),
            Vertex(position: p(-0.5, -0.5,  0.5), color: r),
            Vertex(position: p(-0.5,  0.5,  0.5), color: r),
            Vertex(position: p(-0.5, -0.5, -0.5), color: r),
            Vertex(position: p(-0.5,  0.5,  0.5), color: r),
            Vertex(position: p(-0.5,  0.5, -0.5), color: r),
            
            // Right (+X, cyan)
            Vertex(position: p( 0.5, -0.5,  0.5), color: c),
            Vertex(position: p( 0.5, -0.5, -0.5), color: c),
            Vertex(position: p( 0.5,  0.5, -0.5), color: c),
            Vertex(position: p( 0.5, -0.5,  0.5), color: c),
            Vertex(position: p( 0.5,  0.5, -0.5), color: c),
            Vertex(position: p( 0.5,  0.5,  0.5), color: c),
            
            // Top (+Y, yellow)
            Vertex(position: p(-0.5,  0.5,  0.5), color: y),
            Vertex(position: p( 0.5,  0.5,  0.5), color: y),
            Vertex(position: p( 0.5,  0.5, -0.5), color: y),
            Vertex(position: p(-0.5,  0.5,  0.5), color: y),
            Vertex(position: p( 0.5,  0.5, -0.5), color: y),
            Vertex(position: p(-0.5,  0.5, -0.5), color: y),
            
            // Bottom (-Y, magenta)
            Vertex(position: p(-0.5, -0.5, -0.5), color: m),
            Vertex(position: p( 0.5, -0.5, -0.5), color: m),
            Vertex(position: p( 0.5, -0.5,  0.5), color: m),
            Vertex(position: p(-0.5, -0.5, -0.5), color: m),
            Vertex(position: p( 0.5, -0.5,  0.5), color: m),
            Vertex(position: p(-0.5, -0.5,  0.5), color: m),
        ]
    }
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

struct CubeInstance : Identifiable {
    init(trans: StandardTransformations = StandardTransformations(), id: UUID = UUID()) {
        self.transform = trans
        self.id = id
    }
    
    var transform: StandardTransformations
    var id: UUID;
}

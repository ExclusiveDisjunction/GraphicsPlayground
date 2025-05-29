//
//  CubeMesh.swift
//  Graphics Demo
//
//  Created by Hollan on 5/29/25.
//

import MetalKit
import Metal

struct Vertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}

class CubeMesh  {
    var vertexBuffer: MTLBuffer
    
    init?(device: MTLDevice) {
        let vertices: [Vertex] = CubeMesh.generateCubeVertices()
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: []) else {
            return nil;
        }
        
        self.vertexBuffer = vertexBuffer
    }
    
    static func generateCubeVertices() -> [Vertex] {
        return [];
    }
}

struct CubeInstance : Identifiable {
    var modelMatrix: float4x4
    var id: UUID;
}

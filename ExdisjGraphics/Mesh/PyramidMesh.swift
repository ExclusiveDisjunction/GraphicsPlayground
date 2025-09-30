//
//  PyramidMesh.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import Metal
import MetalKit

public final class PyramidMesh : PrimativeMesh {
    public static var name: String { "Pyramid" }
    public var buffer: MTLBuffer;
    public var count: Int;
    
    public init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        let vertices: [Vertex] = Self.generateVertices()
        self.count = vertices.count
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count) else {
            throw .buffer
        }
        
        self.buffer = vertexBuffer
    }
    
    public static func generateVertices() -> [Vertex] {
        let red = SIMD3<Float>(1, 0, 0)
        let green = SIMD3<Float>(0, 1, 0)
        let blue = SIMD3<Float>(0, 0, 1)
        let yellow = SIMD3<Float>(1, 1, 0)
        let white = SIMD3<Float>(1, 1, 1)
        
        let top = SIMD3<Float>(0, 1, 0)
        let bl = SIMD3<Float>(-0.5, 0, -0.5) // bottom-left
        let br = SIMD3<Float>(0.5, 0, -0.5)  // bottom-right
        let tr = SIMD3<Float>(0.5, 0, 0.5)   // top-right
        let tl = SIMD3<Float>(-0.5, 0, 0.5)  // top-left
        
        return [
            // Front face (red)
            Vertex(position: top, color: red),
            Vertex(position: bl, color: red),
            Vertex(position: br, color: red),
            
            // Right face (green)
            Vertex(position: top, color: green),
            Vertex(position: br, color: green),
            Vertex(position: tr, color: green),
            
            // Back face (blue)
            Vertex(position: top, color: blue),
            Vertex(position: tr, color: blue),
            Vertex(position: tl, color: blue),
            
            // Left face (yellow)
            Vertex(position: top, color: yellow),
            Vertex(position: tl, color: yellow),
            Vertex(position: bl, color: yellow),
            
            // Base (white) — 2 triangles
            Vertex(position: bl, color: white),
            Vertex(position: br, color: white),
            Vertex(position: tr, color: white),
            
            Vertex(position: bl, color: white),
            Vertex(position: tr, color: white),
            Vertex(position: tl, color: white)
        ]
    }
}

//
//  CubeMesh.swift
//  Graphics Demo
//
//  Created by Hollan on 5/29/25.
//

import MetalKit
import Metal

public final class CubeMesh : PrimativeMesh {
    public static var name: String { "Cube" }
    public var buffer: MTLBuffer
    public var count: Int;
    
    public init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        let vertices: [Vertex] = CubeMesh.generateVertices()
        self.count = vertices.count
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: []) else {
            throw .buffer
        }
        
        self.buffer = vertexBuffer
    }
    
    public static func generateVertices() -> [Vertex] {
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

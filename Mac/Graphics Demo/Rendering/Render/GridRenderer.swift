//
//  CubeSceneRenderer.swift
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

import Metal
import MetalKit

struct AxisMesh : MeshBasis {
    init(_ device: any MTLDevice, dim: Int) throws(MissingMetalComponentError) {
        let vertices = Self.generateVertices(dim);
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count) else {
            throw .buffer
        }
        
        self.buffer = buffer
        self.count = vertices.count
    }
    
    static func generateVertices(_ dim: Int) -> [Vertex] {
        let r = SIMD3<Float>(1.0, 0.0, 0.0)
        let g = SIMD3<Float>(0.0, 1.0, 0.0)
        let b = SIMD3<Float>(0.0, 0.0, 1.0)
        let k = SIMD3<Float>(0.7, 0.7, 0.7);
        
        var result: [Vertex] = [
            .init(position: .init(Float(-dim), 0, 0), color: r),
            .init(position: .init(Float(dim), 0, 0), color: r),
            
            .init(position: .init(0, Float(-dim), 0), color: g),
            .init(position: .init(0, Float(dim), 0), color: g),
            
            .init(position: .init(0, 0, Float(-dim)), color: b),
            .init(position: .init(0, 0, Float(dim)), color: b)
        ]
        
        
        for i in (-dim)...dim {
            if i == 0 {
                continue;
            }
            
            result.append(.init(position: .init(Float(i), 0, Float(-dim)), color: k))
            result.append(.init(position: .init(Float(i), 0, Float(dim)), color: k))
            
            result.append(.init(position: .init(Float(-dim), 0, Float(i)), color: k))
            result.append(.init(position: .init(Float(dim), 0, Float(i)), color: k))
        }
        
        return result;
    }
    
    static var name: String { "Axis" }
    var buffer: MTLBuffer
    var count: Int
}

final class GridRenderer : RendererBasis3d, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;
    
    let axis: AxisMesh;
    var camera: CameraController;
    
    init(_ device: MTLDevice, camera: CameraController) throws(MissingMetalComponentError) {
        do {
            self.pipeline = try Self.buildPipeline(device: device)
            self.axis = try AxisMesh(device, dim: 10)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        self.camera = camera
        
        try super.init(device)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.updateMTKView(view, size: size)
    }
    
    func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: commandQueue) else {
            print("the required components for rendering could not be found")
            return;
        }
        
        context.setColorAttachments()
        context.setDepthTexture(depthTexture)
        
        guard let renderEncoder = context.makeEncoder() else {
            print("unable to create the render encoder")
            return;
        }
        
        var viewMatrix = camera.cameraMatrix;
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(axis.buffer, offset: 0, index: 0);
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.stride, index: 1);
        renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.stride, index: 2);
        
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: axis.count)
        
        renderEncoder.endEncoding()
        context.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        try Self.makeSimplePipeline(device, vertex: "axisVertex", fragment: "axisFragment")
    }
}

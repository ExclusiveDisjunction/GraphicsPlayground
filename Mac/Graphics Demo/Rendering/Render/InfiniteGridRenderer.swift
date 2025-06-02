//
//  InfiniteGridRenderer.swift
//  Graphics Demo
//
//  Created by Hollan on 6/1/25.
//

import MetalKit
import Metal
import simd

struct XZAxisPlaneMesh : MeshBasis {
    static var name: String { "XZAxisPlaneMesh" }
    var buffer: MTLBuffer;
    var count: Int;
    
    init(_ device: MTLDevice, size: Int = 1000) throws(MissingMetalComponentError) {
        let points = Self.generateVertices(size);
        
        guard let buffer = device.makeBuffer(bytes: points, length: MemoryLayout<SIMD3<Float>>.stride * points.count) else {
            throw .buffer
        }
        
        self.buffer = buffer
        self.count = points.count
    }
    
    static func generateVertices(_ size: Int) -> [SIMD3<Float>] {
        let size = Float(size);
        
        return [
            .init(-size, 0, -size),
            .init( size, 0, -size),
            .init(-size, 0,  size),
            
            .init( size, 0, -size),
            .init( size, 0,  size),
            .init(-size, 0,  size)
        ];
    }
}

final class InfiniteGridRenderer : RendererBasis3d, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;

    let axis: XZAxisPlaneMesh;
    var camera: CameraController;
    
    init(_ device: MTLDevice, camera: CameraController) throws(MissingMetalComponentError) {
        do {
            self.pipeline = try Self.buildPipeline(device: device)
            self.axis = try XZAxisPlaneMesh(device, size: 5)
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
        var modelMatrix = float4x4(translation: .init())
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(axis.buffer, offset: 0, index: 0);
        renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.stride, index: 1);
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.stride, index: 2);
        renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.stride, index: 3);
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: axis.count)
        
        renderEncoder.endEncoding()
        context.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        return try Self.makeSimplePipeline(device, vertex: "infiniteAxisVertex", fragment: "infiniteAxisFragment")
    }
}

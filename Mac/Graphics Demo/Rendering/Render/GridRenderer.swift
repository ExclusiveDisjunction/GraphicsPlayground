//
//  CubeSceneRenderer.swift
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

import Metal
import MetalKit

struct AxisMesh : PrimativeMesh {
    init(_ device: any MTLDevice) throws(MissingMetalComponentError) {
        let vertices = Self.generateVertices();
        
        guard let buffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count) else {
            throw .buffer
        }
        
        self.buffer = buffer
        self.count = vertices.count
    }
    
    static func generateVertices() -> [Vertex] {
        let r = SIMD3<Float>(1.0, 0.0, 0.0)
        let g = SIMD3<Float>(0.0, 1.0, 0.0)
        let b = SIMD3<Float>(0.0, 0.0, 1.0)
        
        return [
            .init(position: .init(-5, 0, 0), color: r),
            .init(position: .init(5, 0, 0), color: r),
            
            .init(position: .init(0, -5, 0), color: g),
            .init(position: .init(0, 5, 0), color: g),
            
            .init(position: .init(0, 0, -5), color: b),
            .init(position: .init(0, 0, 5), color: b)
        ]
    }
    
    static var name: String { "Axis" }
    var buffer: MTLBuffer
    var count: Int
}

final class GridRenderer : NSObject, MTKViewDelegate {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    //var gridCompute: MTLComputePipelineState;
    var depthStencilState: MTLDepthStencilState;
    var depthTexture: MTLTexture?;
    
    let axis: AxisMesh;
    var camera: CameraController;
    var projectionMatrix: float4x4;
    
    init(_ device: MTLDevice, camera: CameraController) throws(MissingMetalComponentError) {
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw .commandQueue
        }
        self.commandQueue = commandQueue
        
        do {
            self.pipeline = try Self.buildPipeline(device: self.device)
            self.axis = try AxisMesh(device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        self.camera = camera
        self.projectionMatrix = float4x4(perspectiveFov: .pi / 3, aspectRatio: 1, nearZ: 0.1, farZ: 100)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            throw .depthStencil
        }
        
        self.depthStencilState = depthStencilState;
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width / size.height)
        self.projectionMatrix = float4x4(perspectiveFov: .pi / 3, aspectRatio: aspect, nearZ: 0.1, farZ: 100)
        
        let width = size.width == 0 ? 1 : size.width;
        let height = size.height == 0 ? 1 : size.height;
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(width),
            height: Int(height),
            mipmapped: false
        )
        desc.usage = .renderTarget
        desc.storageMode = .private
        self.depthTexture = device.makeTexture(descriptor: desc)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("the required components for rendering could not be found")
            return;
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.3, 0.3, 0.3, 1);
        renderPassDescriptor.colorAttachments[0].loadAction = .clear;
        renderPassDescriptor.colorAttachments[0].storeAction = .store;
        
        if let depth = depthTexture {
            renderPassDescriptor.depthAttachment.texture = depth
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
            renderPassDescriptor.depthAttachment.clearDepth = 1.0
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
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
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        
        guard  let vertexFunction = library.makeFunction(name: "axisVertex") else {
            throw MissingMetalComponentError.libraryFunction("axisVertex")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "axisFragment") else {
            throw MissingMetalComponentError.libraryFunction("axisFragment")
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    /*
     static func buildComputePipeline(device: MTLDevice) throws -> MTLComputePipelineState {
         
     }
     */
}

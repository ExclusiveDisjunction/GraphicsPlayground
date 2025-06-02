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

final class InfiniteGridRenderer : NSObject, MTKViewDelegate {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    var depthStencilState: MTLDepthStencilState;
    var depthTexture: MTLTexture?;
    
    let axis: XZAxisPlaneMesh;
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
            self.axis = try XZAxisPlaneMesh(device, size: 1000)
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
        self.projectionMatrix = float4x4(perspectiveFov: .pi / 6, aspectRatio: aspect, nearZ: 0.1, farZ: 100)
        
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
        
        guard  let vertexFunction = library.makeFunction(name: "infiniteAxisVertex") else {
            throw MissingMetalComponentError.libraryFunction("infiniteAxisVertex")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "infiniteAxisFragment") else {
            throw MissingMetalComponentError.libraryFunction("infiniteAxisFragment")
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

//
//  HompageRender.swift
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

import SwiftUI
import Metal
import MetalKit

final class HomepageRender : RendererBasis3d, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;
    
    var frame: Int32 = 0;
    var mesh: PyramidMesh;
    var p1Loc: float4x4
    var p2Loc: float4x4
    var buffer: MTLBuffer;
    var camera: float4x4
    
    override init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw .commandQueue
        }
        self.commandQueue = commandQueue
        
        do {
            self.pipeline = try Self.buildPipeline(device: device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        guard let buffer = device.makeBuffer(length: MemoryLayout<float4x4>.stride) else {
            throw .buffer
        }
        self.buffer = buffer
        
        do {
            self.mesh = try PyramidMesh(device)
        }
        catch let e {
            throw e
        }
    
        self.p1Loc = float4x4(translation: .init(0, 1, 0))
        self.p2Loc = float4x4(translation: .init(0, -1, 0))
        self.camera = float4x4(translation: .init(0, 0, -5))
        self.projection = Self.makePerspective(aspectRatio: 1)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            throw .depthStencil
        }
        self.depthStencilState = depthStencilState
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width / size.height)
        self.projection = Self.makePerspective(aspectRatio: aspect)
        
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
            print("Internal needed components not present")
            return
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
            print("unable to create render encoder")
            return;
        }
        
        let angle = Float(frame) / 60 / (.pi / 8); //Every 60 frames, it will go pi/8 radians around
        let xAngle = Float(frame) / 120 / (.pi / 8);
        let p1Final = p1Loc * float4x4(rotation: .init(xAngle, -angle, .pi)) //* float4x4(scaling: .init(0, -1, 0));
        let p2Final = p2Loc * float4x4(rotation: .init(xAngle, -angle, 0));
        
        memcpy(buffer.contents(), [p1Final, p2Final], MemoryLayout<float4x4>.stride * 2)
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(mesh.buffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&projection, length: MemoryLayout<float4x4>.stride, index: 2);
        renderEncoder.setVertexBytes(&camera, length: MemoryLayout<float4x4>.stride, index: 3);
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.count, instanceCount: 2)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        frame += 1;
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        
        guard  let vertexFunction = library.makeFunction(name: "simple3dVertex") else {
            throw MissingMetalComponentError.libraryFunction("simple3dVertex")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "simple3dFragment") else {
            throw MissingMetalComponentError.libraryFunction("simple3dFragment")
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func makePerspective(fov: Float = .pi / 3, aspectRatio: Float, nearZ: Float = 0.1, farZ: Float = 100) -> float4x4 {
        float4x4(perspectiveFov: fov, aspectRatio: aspectRatio, nearZ: nearZ, farZ: farZ)
    }
}

//
//  TriangleRender.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import Metal
import MetalKit
import SwiftUI

final class TriangleRender : NSObject, MTKViewDelegate {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    
    init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw .commandQueue
        }
        self.commandQueue = commandQueue
        
        do {
            self.pipeline = try Self.buildPipeline(device: self.device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("key components for rendering could not be made")
            return;
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0.5, 1.0);
        renderPassDescriptor.colorAttachments[0].loadAction = .clear;
        renderPassDescriptor.colorAttachments[0].storeAction = .store;
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("unable to create the render encoder")
            return;
        }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3);
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        
        guard let vertexFunction = library.makeFunction(name: "triangleVertexMain") else {
            throw MissingMetalComponentError.libraryFunction("triangleVertexMain")
        }
        guard let fragmentFunction = library.makeFunction(name: "triangleFragmentMain") else {
            throw MissingMetalComponentError.libraryFunction("triangleFragmentMain")
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

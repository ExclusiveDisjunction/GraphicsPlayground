//
//  TriangleRender.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import Metal
import MetalKit
import SwiftUI

final class TriangleRender : NSObject, MTKViewDelegate, RendererBasis {
    var parent: MetalView<TriangleRender>;
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    
    init?(_ parent: MetalView<TriangleRender>) {
        self.parent = parent;
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("no device could be made");
            return nil;
        }
        
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            print("no command queue could be made")
            return nil
        }
        
        self.commandQueue = commandQueue
        
        do {
            guard let pipeline = try Self.buildPipeline(device: self.device) else {
                return nil
            }
            
            self.pipeline = pipeline
        }
        catch let e {
            print("unable to create a pipeline, error \(e)")
            return nil
        }
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("no command buffer could be made")
            return
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("no render pass descriptor could be found");
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
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState? {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        guard let library = device.makeDefaultLibrary() else {
            print("failed to get the default library");
            return nil;
        }
        
        guard let vertexFunction = library.makeFunction(name: "vertexMain"),
              let fragmentFunction = library.makeFunction(name: "fragmentMain") else {
            print("unable to create the vertex or fragement functions")
            return nil
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

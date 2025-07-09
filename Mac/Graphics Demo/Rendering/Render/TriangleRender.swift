//
//  TriangleRender.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import Metal
import MetalKit
import SwiftUI
import ExdisjGraphics

final class TriangleRender : RendererBasis, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;
    
    override init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        do {
            self.pipeline = try Self.buildPipeline(device: device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        try super.init(device)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: commandQueue) else {
            return;
        }
        
        context.setColorAttachments()
        
        guard let renderEncoder = context.makeEncoder() else {
            return;
        }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3);
        
        renderEncoder.endEncoding()
        context.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        return try self.makeSimplePipeline(device, vertex: "triangleVertexMain", fragment: "triangleFragmentMain", is2d: true)
    }
}

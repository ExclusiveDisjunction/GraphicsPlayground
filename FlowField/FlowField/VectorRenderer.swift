//
//  Untitled.swift
//  FlowField
//
//  Created by Hollan Sellars on 11/8/25.
//

import Metal
import MetalKit
import simd

public class VectorRenderer : RendererBasis, MTKViewDelegate, @unchecked Sendable {
    public init(_ device: MTLDevice, sizeX: Int, sizeY: Int) throws(MissingMetalComponentError) {
        
        let stride = MemoryLayout<FlowVector>.stride;
        guard let buffer = device.makeBuffer(length: stride * sizeX * sizeY, options: .storageModeShared) else {
            throw MissingMetalComponentError.buffer
        }
        
        do {
            self.pipeline = try Self.makeSimplePipeline(device, vertex: "transformVectorOutputs", fragment: "vectorFragment")
        }
        catch let e {
            throw MissingMetalComponentError.pipeline(e)
        }
        
        self.buffer = buffer;
        self.sizeX = sizeX;
        self.sizeY = sizeY;
        self.count = sizeX * sizeY;
        
        try super.init(device)
        
        self.randomizeBuffer();
    }
    
    private func layoutBuffer(size: CGSize) {
        let access = self.buffer.contents().assumingMemoryBound(to: FlowVector.self);
        let wrapper = UnsafeMutableBufferPointer(start: access, count: self.sizeX * self.sizeY);
        
        let units = SIMD2(Float(size.width) / Float(self.sizeX), Float(size.height) / Float(self.sizeY));
        for i in 0..<self.sizeX {
            for j in 0..<self.sizeY {
                let totalIndex = j * self.sizeX + i;
                
                wrapper[totalIndex].tail = SIMD2(
                    units.x * Float(i),
                    units.y * Float(j)
                )
            }
        }
    }
    private func randomizeBuffer() {
        var rand = SystemRandomNumberGenerator();
        
        let access = self.buffer.contents().assumingMemoryBound(to: FlowVector.self);
        let wrapper = UnsafeMutableBufferPointer(start: access, count: self.sizeX * self.sizeY);
        
        let angRange: ClosedRange<Float> = 0.0...(2.0 * Float.pi);
        let magRange: ClosedRange<Float> = 0.0...10.0;
        
        for i in 0..<wrapper.count {
            wrapper[i].angMag = SIMD2(
                Float.random(in: angRange, using: &rand),
                Float.random(in: magRange, using: &rand)
            )
        }
    }
    
    private let sizeX: Int;
    private let sizeY: Int;
    private let count: Int;
    private let buffer: MTLBuffer;
    private let pipeline: MTLRenderPipelineState;
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.layoutBuffer(size: size)
    }
    public func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: self.commandQueue) else {
            return;
        }
        
        context.setColorAttachments();
        
        guard let encoder = context.makeEncoder() else {
            return;
        }
        
        encoder.setVertexBuffer(self.buffer, offset: 0, index: 0);
        encoder.setRenderPipelineState(self.pipeline)
        
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2, instanceCount: count);
        
        encoder.endEncoding();
        context.commit();
    }
}

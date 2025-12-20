//
//  GridRenderer.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/19/25.
//

import Metal
import MetalKit

public class GridRenderer : RendererBasis, MTKViewDelegate, @unchecked Sendable {
    public init(_ device: any MTLDevice, spacing: Float) throws {
        self.texture = nil;
        self.spacing = spacing;
        
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        
        self.kernel = try .init(
            functionName: "renderGrid",
            using: library,
            device: device
        );
        self.size = .init()
        
        try super.init(device)
    }
    
    public fileprivate(set) var texture: MTLTexture?;
    public var spacing: Float;
    public var thickness: Float = 2.0;
    public fileprivate(set) var size: SIMD2<Float>;
    public fileprivate(set) var kernel: ComputeContext;
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        );
        
        desc.usage = [.shaderRead, .shaderWrite];
        desc.storageMode = .shared;
       
        self.texture = self.device.makeTexture(descriptor: desc);
        self.size = SIMD2(Float(size.width), Float(size.height))
    }
    public func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: self.commandQueue) else {
            return;
        }
        
        context.setColorAttachments();
        
        guard let texture = self.texture else {
            return;
        }
        
        guard let computeEncoder = context.commandBuffer.makeComputeCommandEncoder() else {
            return;
        }
        
        computeEncoder.setComputePipelineState(self.kernel.pipeline);
        computeEncoder.setTexture(self.texture, index: 0)
        computeEncoder.setBytes(&self.spacing, length: MemoryLayout<Float>.stride, index: 0);
        computeEncoder.setBytes(&self.thickness, length: MemoryLayout<Float>.stride, index: 1);
        
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadsPerGrid = MTLSize(
            width: texture.width,
            height: texture.height,
            depth: 1
        );
        
        computeEncoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        
        guard let renderEncoder = context.makeEncoder() else {
            return;
        }
        
        
    }
}

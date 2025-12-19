//
//  ComputeContext.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

import Metal

public struct ComputeContext {
    public let function: MTLFunction;
    public let pipeline: MTLComputePipelineState;
    public var waitingFence: MTLFence?;
    public var updatingFence: MTLFence?;
    
    public init(functionName: String, using: MTLLibrary, device: MTLDevice) throws {
        self.function = try RendererBasis.getMetalFunction(using, name: functionName);
        self.pipeline = try device.makeComputePipelineState(function: function);
    }
    
    public func execute(using: borrowing FrameDrawContext, bufferSetup: (MTLComputeCommandEncoder) throws -> Int) rethrows -> Bool {
        guard let encoder = using.commandBuffer.makeComputeCommandEncoder() else {
            return false;
        }
        
        let count = try bufferSetup(encoder);
        encoder.setComputePipelineState(self.pipeline);
        
        let gridSize = MTLSize(width: count, height: 1, depth: 1);
        let maxComputeSize = self.pipeline.maxTotalThreadsPerThreadgroup;
        var threadsPerThreadgroup = count;
        if count > maxComputeSize {
            threadsPerThreadgroup = maxComputeSize;
        }
        
        if let fence = self.waitingFence {
            encoder.waitForFence(fence)
        }
        
        encoder.dispatchThreads(gridSize, threadsPerThreadgroup: MTLSize(width: threadsPerThreadgroup, height: 1, depth: 1))
        
        if let fence = updatingFence {
            encoder.updateFence(fence)
        }
        
        encoder.endEncoding()
        return true;
    }
    public mutating func resetFences() {
        self.updatingFence = nil;
        self.waitingFence = nil;
    }
}

//
//  Untitled.swift
//  FlowField
//
//  Created by Hollan Sellars on 11/8/25.
//

import Metal
import MetalKit
import simd

public struct BufferResizeError : Error {
    
}

extension ColorSchema {
    public var minHex: Int {
        Int(self.min.x * 255) << 16 | Int(self.min.y * 255) << 8 | Int(self.min.z * 255)
    }
    
    public var maxHex: Int {
        Int(self.max.x * 255) << 16 | Int(self.max.y * 255) << 8 | Int(self.max.z * 255)
    }
    
    public var minCGColor: CGColor {
        CGColor(red: CGFloat(self.min.x), green: CGFloat(self.min.y), blue: CGFloat(self.min.z), alpha: 1.0)
    }
    public var maxCGColor: CGColor {
        CGColor(red: CGFloat(self.max.x), green: CGFloat(self.max.y), blue: CGFloat(self.max.z), alpha: 1.0)
    }
}

public enum FirstTimeState {
    case firstRun
    case resized
    case noChanges
}

public struct ComputeManifest {
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

@Observable
public class VectorRendererProperties {
    public init(panX: Float, panY: Float) {
        self.colors = ColorSchema(min: SIMD3(0.337255, 0.7568628, 0.9098039), max: SIMD3(0.462745, 0.337255, 0.9098039))
        self.zoom = 1;
        self.panX = panX;
        self.panY = panY;
    }
    
    public var colors: ColorSchema;
    public var zoom: Float;
    public var panX: Float;
    public var panY: Float;
}

public class VectorRenderer : RendererBasis, MTKViewDelegate, @unchecked Sendable {
    public init(_ device: MTLDevice, qnty: SIMD2<Int>, size: SIMD2<Float>) throws {
        let stride = MemoryLayout<FlowVector>.stride;
        let count = qnty.x * qnty.y;
        guard let buffer = device.makeBuffer(length: stride * count, options: .storageModeShared) else {
            throw MissingMetalComponentError.buffer
        }
        
        do {
            self.graphicsPipeline = try Self.makeSimplePipeline(device, vertex: "transformVectorOutputs", fragment: "vectorFragment", is2d: true)
        }
        catch let e {
            throw MissingMetalComponentError.pipeline(e)
        }
        
        self.buffer = buffer;
        self.qnty = qnty;
        self.size = size;
        self.count = count;
        self.prop = .init(panX: 0, panY: 0.0);
        
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary;
        }
        
        self.positionManifest = try .init(functionName: "positionVectors", using: library, device: device);
        self.angleManifest = try .init(functionName: "angleVectors", using: library, device: device);
        self.animateManifest = try .init(functionName: "animateVectors", using: library, device: device);
        
        guard let animateFence = device.makeFence() else {
            throw MissingMetalComponentError.fence;
        }
        self.animateManifest.updatingFence = animateFence;
        
        self.projection = float4x4(
            rows: [
                SIMD4(2.0 / size.x, 0.0,          -1.0, 0),
                SIMD4(0,            2.0 / size.y, -1.0, 0),
                SIMD4(0,            0,             1  , 0),
                SIMD4(0,            0,             0  , 1)
            ]
        );
        
        self.prop.colors = ColorSchema(min: SIMD3(0.337255, 0.7568628, 0.9098039), max: SIMD3(0.462745, 0.337255, 0.9098039))

        try super.init(device)
    }
    
    public func resize(qnty: SIMD2<Int>, size: SIMD2<Float>) throws(BufferResizeError) {
        let count = qnty.x * qnty.y;
        let stride = MemoryLayout<FlowVector>.stride;
        
        guard let buffer = device.makeBuffer(length: stride * count, options: .storageModeShared) else {
            throw BufferResizeError()
        }
        
        self.qnty = qnty;
        self.size = size;
        self.count = count;
        self.buffer = buffer;
        
        self.projection = float4x4(
            rows: [
                SIMD4(2.0 / size.x, 0.0,          -1.0, 0),
                SIMD4(0,            2.0 / size.y, -1.0, 0),
                SIMD4(0,            0,             1  , 0),
                SIMD4(0,            0,             0  , 1)
            ]
        );
        
        if state != .firstRun {
            self.state = .resized;
        }
    }

    public fileprivate(set) var qnty: SIMD2<Int>;
    public fileprivate(set) var size: SIMD2<Float>;
    public fileprivate(set) var count: Int;
    public fileprivate(set) var state: FirstTimeState = .firstRun;
    private var buffer: MTLBuffer;
    private let graphicsPipeline: MTLRenderPipelineState;
    private var positionManifest: ComputeManifest;
    private var angleManifest: ComputeManifest;
    private var animateManifest: ComputeManifest;
    private var projection: float4x4;
    
    public var prop: VectorRendererProperties;
    
    private var zoomMatrix: float4x4 {
        float4x4(
            rows:[
                SIMD4(prop.zoom, 0,         0, 0),
                SIMD4(0,         prop.zoom, 0, 0),
                SIMD4(0,         0,         1, 0),
                SIMD4(0,         0,         0, 1)
            ]
        )
    }
    private var panMatrix: float4x4 {
        var result = matrix_identity_float4x4;
        result.columns.3 = SIMD4<Float>(self.prop.panX, self.prop.panY, 0.0, 1);
        
        return result
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = SIMD2(Float(size.width), Float(size.height))
        if state != .firstRun { //The first run is more important, and it must be signaled first.
            self.state = .resized;
        }
    }
    
    public func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: self.commandQueue) else {
            return;
        }
        
        var computeContext = VectorsSetupCx(step: self.size / SIMD2<Float>(self.qnty), sizex: UInt32(self.qnty.x), sizey: UInt32(self.qnty.y), corner: -self.size / 2);
        
        let closure: (MTLComputeCommandEncoder) -> Int = { encoder in
            encoder.setBuffer(self.buffer, offset: 0, index: 0);
            encoder.setBytes(&computeContext, length: MemoryLayout<VectorsSetupCx>.stride, index: 1);
            
            return self.count
        }
        
        switch self.state {
            case .firstRun:
                guard let fenceA = device.makeFence(),
                      let fenceB = device.makeFence() else {
                    return;
                }
                
                self.positionManifest.updatingFence = fenceA;
                self.angleManifest.waitingFence = fenceA;
                self.angleManifest.updatingFence = fenceB;
                self.animateManifest.waitingFence = fenceB;
                
                guard self.positionManifest.execute(using: context, bufferSetup: closure) && self.angleManifest.execute(using: context, bufferSetup: closure) else {
                    return;
                }
            case .resized:
                guard let fence = device.makeFence() else {
                    return;
                }
                
                self.positionManifest.updatingFence = fence;
                self.animateManifest.waitingFence = fence;
                
                guard self.positionManifest.execute(using: context, bufferSetup: closure) else {
                    return;
                }
            case .noChanges:
                guard self.animateManifest.execute(using: context, bufferSetup: closure) else {
                    return
                }
        }
        
        if self.state == .resized || self.state == .firstRun {
            guard self.positionManifest.execute(using: context, bufferSetup: closure) else {
                return;
            }
        }
        if self.state == .firstRun {
            guard self.angleManifest.execute(using: context, bufferSetup: closure) else {
                return;
            }
        }
    
        guard self.animateManifest.execute(using: context, bufferSetup: closure) else {
            return;
        }
        
        var transform = self.projection * self.zoomMatrix * self.panMatrix;
        var thickness = max(min(self.prop.zoom / 2, 1.5), 0.2);
        
        context.setColorAttachments();
        
        guard let renderEncoder = context.makeEncoder() else {
            return;
        }
    
        renderEncoder.setVertexBuffer(self.buffer, offset: 0, index: 0);
        renderEncoder.setVertexBytes(&transform, length: MemoryLayout<float4x4>.stride, index: 1);
        renderEncoder.setVertexBytes(&thickness, length: MemoryLayout<Float>.stride, index: 2);
        renderEncoder.setFragmentBytes(&self.prop.colors, length: MemoryLayout<ColorSchema>.stride, index: 0)
        renderEncoder.setRenderPipelineState(self.graphicsPipeline)
        
        renderEncoder.waitForFence(self.animateManifest.updatingFence!, before: .vertex)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count);
        
        renderEncoder.endEncoding();
        context.commit();
        
        self.positionManifest.resetFences()
        self.angleManifest.resetFences()
        self.animateManifest.waitingFence = nil;
        self.state = .noChanges
    }
}

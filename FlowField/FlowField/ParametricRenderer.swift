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
        self.count = qnty.x * qnty.y;
        guard let parametricBuffer = device.makeBuffer(length: MemoryLayout<ParametricVector>.stride * count, options: .storageModePrivate),
              let renderBuffer = device.makeBuffer(length: MemoryLayout<RenderableVector>.stride * count, options: .storageModePrivate) else {
            throw MissingMetalComponentError.buffer
        }
        
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary;
        }
        
        do {
            self.graphicsBodyPipeline = try Self.makeSimplePipeline(device: device, library: library, vertex: "renderVectorBody", fragment: "vectorFragment", is2d: true);
            self.graphicsTriaglePipeline = try Self.makeSimplePipeline(device: device, library: library, vertex: "renderVectorPoint", fragment: "vectorFragment", is2d: true)
        }
        catch let e {
            throw MissingMetalComponentError.pipeline(e)
        }
        
        self.parametricBuffer = parametricBuffer;
        self.renderBuffer = renderBuffer;
        self.qnty = qnty;
        self.size = size;
        self.prop = .init(panX: 0, panY: 0.0);
        self.requiresPositioning = true;
        
        self.positionManifest = try .init(functionName: "positionVectorsParametric", using: library, device: device);
        self.animateManifest = try .init(functionName: "animateVectorsParametric", using: library, device: device);
        self.transformManifest = try .init(functionName: "transformParametric", using: library, device: device);
        
        guard let animateFence = device.makeFence(), let transformFence = device.makeFence() else {
            throw MissingMetalComponentError.fence;
        }
        self.animateManifest.updatingFence = animateFence;
        self.transformManifest.waitingFence = animateFence;
        self.transformManifest.updatingFence = transformFence;
        self.graphicsFence = transformFence;
        self.clock = ContinuousClock();
        
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
        
        guard let parametricBuffer = device.makeBuffer(length: MemoryLayout<ParametricVector>.stride * count, options: .storageModePrivate),
              let renderBuffer = device.makeBuffer(length: MemoryLayout<RenderableVector>.stride * count, options: .storageModePrivate) else {
            throw BufferResizeError()
        }
        
        self.qnty = qnty;
        self.size = size;
        self.count = count;
        self.parametricBuffer = parametricBuffer;
        self.renderBuffer = renderBuffer;
        
        self.projection = float4x4(
            rows: [
                SIMD4(2.0 / size.x, 0.0,          -1.0, 0),
                SIMD4(0,            2.0 / size.y, -1.0, 0),
                SIMD4(0,            0,             1  , 0),
                SIMD4(0,            0,             0  , 1)
            ]
        );
        
        self.requiresPositioning = true;
    }

    public fileprivate(set) var qnty: SIMD2<Int>;
    public fileprivate(set) var size: SIMD2<Float>;
    public fileprivate(set) var count: Int;
    public fileprivate(set) var requiresPositioning: Bool;
    private var parametricBuffer: MTLBuffer;
    private var renderBuffer: MTLBuffer;
    private let graphicsBodyPipeline: MTLRenderPipelineState;
    private let graphicsTriaglePipeline: MTLRenderPipelineState;
    private let graphicsFence: MTLFence;
    private var positionManifest: ComputeManifest;
    private var animateManifest: ComputeManifest;
    private var transformManifest: ComputeManifest;
    private var projection: float4x4;
    private var timeLast: ContinuousClock.Instant? = nil;
    private var timeTally: Float = 0.0;
    private let clock: ContinuousClock;
    
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
        self.requiresPositioning = true;
    }
    
    public static let attosecondsConversion: Float = pow(10.0, -18.0);
    
    public func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: self.commandQueue) else {
            return;
        }
        
        let currentTimeInstant = self.clock.now;
        let currentTime: Float;
        let timeDelta: Float;
        if let previousTimeInstant = self.timeLast {
            var (secondsElapsed, attoSecondsElapsed) = (currentTimeInstant - previousTimeInstant).components;
            timeDelta = Float(secondsElapsed) + (Float(attoSecondsElapsed) * VectorRenderer.attosecondsConversion);
            
            currentTime = self.timeTally + timeDelta;
            self.timeTally += timeDelta;
        }
        else {
            currentTime = 0.0;
            timeDelta = 0.0;
            self.timeLast = currentTimeInstant;
        }
        
        if true { //self.requiresPositioning
            guard let fence = device.makeFence() else {
                return;
            }
            
            self.positionManifest.updatingFence = fence;
            self.animateManifest.waitingFence = fence;
            
            var positionContext = VectorSetupContext(
                step: self.size / SIMD2<Float>(self.qnty),
                corner: -self.size / 2,
                sizex: UInt32(self.qnty.x),
                sizey: UInt32(self.qnty.y)
            );
            
            let result = self.positionManifest.execute(using: context) { encoder in
                encoder.setBuffer(self.parametricBuffer, offset: 0, index: 0);
                encoder.setBytes(&positionContext, length: MemoryLayout<VectorSetupContext>.stride, index: 1);
                
                return self.count;
            }
            
            guard result else {
                return;
            }
        }
        
        var animateContext = VectorAnimateContext(
            step: self.size / SIMD2<Float>(self.qnty),
            sizex: UInt32(self.qnty.x),
            sizey: UInt32(self.qnty.y),
            time: currentTime,
            deltaTime: timeDelta
        );
        
        
        let animateResult = self.animateManifest.execute(using: context) { encoder in
            encoder.setBuffer(self.parametricBuffer, offset: 0, index: 0);
            encoder.setBytes(&animateContext, length: MemoryLayout<VectorAnimateContext>.stride, index: 1);
            
            return self.count;
        };
        
        guard animateResult else {
            return;
        }
        
        let transformResult = self.transformManifest.execute(using: context) { encoder in
            encoder.setBuffer(self.parametricBuffer, offset: 0, index: 0);
            encoder.setBuffer(self.renderBuffer, offset: 0, index: 1);
            
            var thickness: Float = max(min(self.prop.zoom / 2, 1.5), 1);
            
            encoder.setBytes(&thickness, length: MemoryLayout<Float>.stride, index: 2);
            
            return self.count
        };
        
        guard transformResult else {
            return;
        }
        
        var renderContext = VectorVertexContext(
            zoom: self.prop.zoom,
            transform: self.projection * self.zoomMatrix * self.panMatrix
        );
        context.setColorAttachments();
        
        guard let renderEncoder = context.makeEncoder() else {
            return;
        }
        
        
        renderEncoder.setVertexBuffer(self.renderBuffer, offset: 0, index: 0);
        renderEncoder.setVertexBytes(&renderContext, length: MemoryLayout<VectorVertexContext>.stride, index: 1);
        renderEncoder.setFragmentBytes(&self.prop.colors, length: MemoryLayout<ColorSchema>.stride, index: 0)
        renderEncoder.setRenderPipelineState(self.graphicsBodyPipeline)
        
        renderEncoder.waitForFence(self.graphicsFence, before: .vertex)
        
        renderEncoder.setCullMode(.none)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count);
        
        renderEncoder.setRenderPipelineState(self.graphicsTriaglePipeline)
        renderEncoder.setCullMode(.none)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: count);
        
        renderEncoder.endEncoding();
        
        context.commit();
        
        self.positionManifest.resetFences();
        self.animateManifest.waitingFence = nil;
        self.requiresPositioning = false;
    }
}

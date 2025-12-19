//
//  VectorFieldRenderer.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//


import Metal
import MetalKit
import simd

public class VectorFieldRenderer : RendererBasis, MTKViewDelegate, @unchecked Sendable {
    public init(_ device: MTLDevice, qnty: SIMD2<Int>, size: SIMD2<Float>, vectorSize stride: Int, positionFunc: String, animateFunc: String, transformFunc: String) throws {
        self.count = qnty.x * qnty.y;
        guard let inputBuffer = device.makeBuffer(length: stride * count, options: .storageModePrivate),
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
        
        self.inputBuffer = inputBuffer;
        self.renderBuffer = renderBuffer;
        self.qnty = qnty;
        self.size = size;
        self.prop = .init(panX: 0, panY: 0.0);
        self.requiresPositioning = true;
        
        self.positionManifest = try .init(functionName: positionFunc, using: library, device: device);
        self.animateManifest = try .init(functionName: animateFunc, using: library, device: device);
        self.transformManifest = try .init(functionName: transformFunc, using: library, device: device);
        
        guard let animateFence = device.makeFence(), let transformFence = device.makeFence() else {
            throw MissingMetalComponentError.fence;
        }
        self.animateManifest.updatingFence = animateFence;
        self.transformManifest.waitingFence = animateFence;
        self.transformManifest.updatingFence = transformFence;
        self.graphicsFence = transformFence;
        self.timer = .init()
        
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
    
    public var prop: VectorRendererProperties;
    public fileprivate(set) var qnty: SIMD2<Int>;
    public fileprivate(set) var size: SIMD2<Float>;
    public fileprivate(set) var count: Int;
    private var requiresPositioning: Bool;
    
    private var inputBuffer: MTLBuffer;
    private var renderBuffer: MTLBuffer;
    public let graphicsBodyPipeline: MTLRenderPipelineState;
    public let graphicsTriaglePipeline: MTLRenderPipelineState;
    public let graphicsFence: MTLFence;
    public fileprivate(set) var positionManifest: ComputeContext;
    public fileprivate(set) var animateManifest: ComputeContext;
    public fileprivate(set) var transformManifest: ComputeContext;
    private var projection: float4x4;
    private var timer: TimeManager;
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = SIMD2(Float(size.width), Float(size.height))
        self.requiresPositioning = true;
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
        self.inputBuffer = parametricBuffer;
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
    
    public func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: self.commandQueue) else {
            return;
        }
        
        if self.requiresPositioning {
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
                encoder.setBuffer(self.inputBuffer, offset: 0, index: 0);
                encoder.setBytes(&positionContext, length: MemoryLayout<VectorSetupContext>.stride, index: 1);
                
                return self.count;
            }
            
            guard result else {
                return;
            }
        }
        
        let timeSlice = self.timer.step();
        
        var animateContext = VectorAnimateContext(
            step: self.size / SIMD2<Float>(self.qnty),
            size: self.size,
            sizex: UInt32(self.qnty.x),
            sizey: UInt32(self.qnty.y),
            time: timeSlice.timeElapsed,
            deltaTime: timeSlice.timeDelta
        );
        
        let animateResult = self.animateManifest.execute(using: context) { encoder in
            encoder.setBuffer(self.inputBuffer, offset: 0, index: 0);
            encoder.setBytes(&animateContext, length: MemoryLayout<VectorAnimateContext>.stride, index: 1);
            
            return self.count;
        };
        
        guard animateResult else {
            return;
        }
        
        let mag: Float;
        do {
            let magA: Float;
            //let magB: Float;
            
            magA = 0.5 * min(animateContext.step.x, animateContext.step.y);
            
            mag = magA; // max(magA, magB);
        }
        var transformContext = TransformContext(
            thickness: simd_clamp(self.prop.zoom, 2, 5),
            magnitude: mag
        )
        
        let transformResult = self.transformManifest.execute(using: context) { encoder in
            encoder.setBuffer(self.inputBuffer, offset: 0, index: 0);
            encoder.setBuffer(self.renderBuffer, offset: 0, index: 1);
            
            encoder.setBytes(&transformContext, length: MemoryLayout<TransformContext>.stride, index: 2);
            
            return self.count
        };
        
        guard transformResult else {
            return;
        }
        
        var renderContext = VectorVertexContext(
            zoom: self.prop.zoom,
            transform: self.projection * self.prop.zoomMatrix * self.prop.panMatrix
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

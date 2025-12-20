//
//  GridRenderer.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/19/25.
//

import Metal
import MetalKit

@Observable
public class ObservableGridProperties {
    public init(spacing: Float, thickness: Float, background: SIMD4<Float> = .init(0.33, 0.33, 0.33, 1.0), line: SIMD4<Float> = .init(1.0, 1.0, 1.0, 1.0)) {
        self.spacing = spacing;
        self.thickness = thickness;
        self.background = background
        self.line = line;
    }
    
    public var spacing: Float;
    public var thickness: Float;
    public var background: SIMD4<Float>;
    public var line: SIMD4<Float>;
    public var offsetX: Float = 0.0;
    public var offsetY: Float = 0.0;
    public var offset: SIMD2<Float> {
        .init(self.offsetX, self.offsetY)
    }
    public var zoom: Float = 1.0;
}

public class GridRenderer : RendererBasis, MTKViewDelegate, @unchecked Sendable {
    public init(_ device: any MTLDevice, prop: ObservableGridProperties) throws {
        self.texture = nil;
        self.prop = prop;
        
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        guard let fence = device.makeFence() else {
            throw MissingMetalComponentError.fence
        }
        
        self.renderPipelineState = try Self.makeSimplePipeline(device: device, library: library, vertex: "gridVertex", fragment: "gridFragment", is2d: true)
        self.graphicsFence = fence;
        
        self.kernel = try .init(
            functionName: "renderGrid",
            using: library,
            device: device
        );
        self.kernel.updatingFence = fence;
        self.size = .init()
        
        try super.init(device)
    }
    
    public var prop: ObservableGridProperties;
    private var texture: MTLTexture?;
    public fileprivate(set) var size: SIMD2<Float>;
    private var kernel: ComputeContext;
    private let renderPipelineState: MTLRenderPipelineState;
    private let graphicsFence: MTLFence;
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
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
        guard var context = FrameDrawContext(view: view, queue: self.commandQueue) else {
            return;
        }
        
        context.setColorAttachments();
        
        guard let texture = self.texture else {
            context.commit();
            return;
        }
        
        guard let computeEncoder = context.commandBuffer.makeComputeCommandEncoder() else {
            context.commit();
            return;
        }
        
        //let thickness = prop.thickness * prop.zoom;
        var gridProp = GridProperties(
            thickness: prop.thickness,
            spacing: prop.spacing,
            zoom: prop.zoom,
            offset: prop.offset,
            background: prop.background,
            line: prop.line
        );
        
        computeEncoder.setComputePipelineState(self.kernel.pipeline);
        computeEncoder.setTexture(self.texture, index: 0)
        computeEncoder.setBytes(&gridProp, length: MemoryLayout<GridProperties>.stride, index: 0);
        
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
        
        renderEncoder.setRenderPipelineState(self.renderPipelineState);
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.waitForFence(self.graphicsFence, before: .fragment);
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding()
        context.commit()
    }
}

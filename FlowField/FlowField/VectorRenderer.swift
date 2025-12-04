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
    public init(_ device: MTLDevice, qnty: SIMD2<Int>, size: SIMD2<Float>) throws(MissingMetalComponentError) {
        
        let stride = MemoryLayout<FlowVector>.stride;
        let count = qnty.x * qnty.y;
        guard let buffer = device.makeBuffer(length: stride * count, options: .storageModeShared) else {
            throw MissingMetalComponentError.buffer
        }
        
        do {
            self.pipeline = try Self.makeSimplePipeline(device, vertex: "transformVectorOutputs", fragment: "vectorFragment", is2d: true)
        }
        catch let e {
            throw MissingMetalComponentError.pipeline(e)
        }
        
        self.buffer = buffer;
        self.qnty = qnty;
        self.size = size;
        self.count = count;
        self.prop = .init(panX: 0, panY: 0.0);
        
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
        
        self.randomizeBuffer();
    }
    
    private func layoutBuffer(size: CGSize) {
        let access = self.buffer.contents().assumingMemoryBound(to: FlowVector.self);
        let wrapper = UnsafeMutableBufferPointer(start: access, count: self.count);
        
        // The total world space is (0, 0) -> (w, h).
        // The total number of elements in the x direction is qnty.x, and y follows.
        // We start from (0, 0) in world space up to (w, h), stepping by (w / qnty.x, h / qnty.y);
        
        let step = self.size / SIMD2<Float>(self.qnty);
        let corner = -self.size / 2;
        for i in 0..<self.qnty.x {
            let x = step.x * Float(i);
            for j in 0..<self.qnty.y {
                let totalIndex = j * self.qnty.x + i;
                
                wrapper[totalIndex].tail = corner + SIMD2(
                    x,
                    Float(j) * step.y
                )
            }
        }
    }
    private func randomizeBuffer() {
        let access = self.buffer.contents().assumingMemoryBound(to: FlowVector.self);
        let wrapper = UnsafeMutableBufferPointer(start: access, count: self.count);
        
        let step = self.size / SIMD2<Float>(self.qnty);
        var k = 0;
        for i in 0..<qnty.x {
            let x = Float(i) * step.x;
            for j in 0..<qnty.y {
                let y = Float(j) * step.y;
                let target = SIMD2(sin(x), sin(y));
                
                let diff = (target - wrapper[k].tail);
                let mag = sqrt(diff.x * diff.x + diff.y * diff.y);
                let angle = atan2(diff.y, diff.x);
                wrapper[k].angMag = SIMD2(
                    angle,
                    mag
                )
                k += 1;
            }
        }
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
        
        self.randomizeBuffer()
    }

    public fileprivate(set) var qnty: SIMD2<Int>;
    public fileprivate(set) var size: SIMD2<Float>;
    public fileprivate(set) var count: Int;
    private var buffer: MTLBuffer;
    private let pipeline: MTLRenderPipelineState;
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
        
        var transform = self.projection * self.zoomMatrix * self.panMatrix;
        var thickness = max(min(self.prop.zoom / 2, 1.5), 0.2);
    
        encoder.setVertexBuffer(self.buffer, offset: 0, index: 0);
        encoder.setVertexBytes(&transform, length: MemoryLayout<float4x4>.stride, index: 1);
        encoder.setVertexBytes(&thickness, length: MemoryLayout<Float>.stride, index: 2);
        encoder.setFragmentBytes(&self.prop.colors, length: MemoryLayout<ColorSchema>.stride, index: 0)
        encoder.setRenderPipelineState(self.pipeline)
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count);
        
        encoder.endEncoding();
        context.commit();
    }
}

import SwiftUI

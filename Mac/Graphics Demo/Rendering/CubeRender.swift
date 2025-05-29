//
//  CubeRender.swift
//  Graphics Demo
//
//  Created by Hollan on 5/24/25.
//

import MetalKit
import Metal
import Foundation
import simd

extension float4x4 {
    init(translation t: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(t, 1)
    }
    
    init(perspectiveFov fovY: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let y = 1 / tan(fovY * 0.5)
        let x = y / aspectRatio
        let z = farZ / (nearZ - farZ)
        
        self.init(SIMD4<Float>( x,  0,  0,   0),
                  SIMD4<Float>( 0,  y,  0,   0),
                  SIMD4<Float>( 0,  0,  z,  -1),
                  SIMD4<Float>( 0,  0,  z * nearZ,  0))
    }
    
    static func radians_from_degrees(_ degrees: Float) -> Float {
        return degrees * (.pi / 180)
    }
}

final class CubeRender : NSObject, MTKViewDelegate, RendererBasis {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    
    var cubeMesh: CubeMesh;
    var cubeInstances: [CubeInstance];
    var instanceBuffer: MTLBuffer;
    var viewMatrix: float4x4;
    var projectionMatrix: float4x4;
    
    init?(_ device: MTLDevice)  {
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
        
        guard let cubeMesh = CubeMesh(device: device) else {
            print("unable to create the cube mesh");
            return nil;
        }
        
        self.cubeMesh = cubeMesh;
        self.cubeInstances = [];
        
        let bufferSize = MemoryLayout<float4x4>.stride * cubeInstances.count;
        guard let instanceBuffer = device.makeBuffer(length: bufferSize, options: []) else {
            print("unable to create instance buffer");
            return nil;
        }
        self.instanceBuffer = instanceBuffer;
        
        self.viewMatrix = float4x4(translation: SIMD3<Float>(0, 0, -5)).inverse;
        
        //let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        //self.projectionMatrix = float4x4(perspectiveFov: )
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return;
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("no command buffer could be madee")
            return
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("no render pass descriptor could be found");
            return;
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.3, 0.3, 0.3, 1);
        renderPassDescriptor.colorAttachments[0].loadAction = .clear;
        renderPassDescriptor.colorAttachments[0].storeAction = .store;
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("unable to create the render encoder")
            return;
        }
        
        let instanceMatrices = cubeInstances.map { $0.modelMatrix };
        //memcpy(instanceBuffer.contents(), instanceMatrices, ...);
        
        renderEncoder.setRenderPipelineState(pipeline)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState? {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        guard let library = device.makeDefaultLibrary() else {
            print("failed to get the default library")
            return nil
        }
        
        guard let vertexFunction = library.makeFunction(name: "cubeVertexMain"),
              let fragmentFunction = library.makeFunction(name: "cubeFragmentMain") else {
            print("unable to create the vertex or fragment functions")
            return nil
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

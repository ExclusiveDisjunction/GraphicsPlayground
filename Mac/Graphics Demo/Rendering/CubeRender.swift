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
    init(perspectiveFov fovY: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let y = 1 / tan(fovY * 0.5)
        let x = y / aspectRatio
        let z = farZ / (nearZ - farZ)
        
        self.init(SIMD4<Float>( x,  0,  0,   0),
                  SIMD4<Float>( 0,  y,  0,   0),
                  SIMD4<Float>( 0,  0,  z,  -1),
                  SIMD4<Float>( 0,  0,  z * nearZ,  0))
    }
}

@Observable
final class CubeInstanceManager {
    init?(_ device: MTLDevice, data: [CubeInstance] = [.init()] ) {
        self.data = data;
        
        let bufferSize = MemoryLayout<float4x4>.stride * data.count;
        guard let instanceBuffer = device.makeBuffer(length: bufferSize, options: []) else {
            print("unable to create instance buffer");
            return nil;
        }
        self.buffer = instanceBuffer;
        self.device = device;
    }
    
    @ObservationIgnored private var device: MTLDevice;
    @ObservationIgnored fileprivate var data: [CubeInstance];
    @ObservationIgnored fileprivate var buffer: MTLBuffer;
    
    private func resizeBuffer() {
        let bufferSize = MemoryLayout<float4x4>.stride * data.count;
        guard let instanceBuffer = device.makeBuffer(length: bufferSize, options: []) else {
            fatalError("Unable to resize command buffer for cube renderer")
        }
        self.buffer = instanceBuffer;
    }
    
    var instances: [CubeInstance] {
        data
    }
    
    func addInstance() {
        data.append(.init());
        resizeBuffer()
    }
    func removeInstance(_ id: CubeInstance.ID) {
        data.removeAll(where: { $0.id == id } )
        resizeBuffer()
    }
    func removeInstances(_ id: Set<CubeInstance.ID>) {
        data.removeAll(where: { id.contains($0.id) } )
        resizeBuffer()
    }
}

final class CubeRender : NSObject, MTKViewDelegate, RendererBasis {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    
    var cubeMesh: CubeMesh;
    var instances: CubeInstanceManager;
    var viewMatrix: float4x4;
    var projectionMatrix: float4x4;
    
    init?(_ device: MTLDevice)  {
        self.device = device;
    
        print("cube render init called")
        
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
        
        
        self.viewMatrix = float4x4(translation: SIMD3<Float>(0, 0, -5)).inverse;
        self.projectionMatrix = matrix_identity_float4x4
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width / size.height)
        self.projectionMatrix = float4x4(perspectiveFov: .pi / 3, aspectRatio: aspect, nearZ: 0.1, farZ: 100)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            print("no current drawable");
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
        
        let instanceMatrices = instances.data.map { $0.transform.modelMatrix };
        memcpy(instances.buffer.contents(), instanceMatrices, MemoryLayout<float4x4>.stride * instanceMatrices.count);
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(cubeMesh.vertexBuffer, offset: 0, index: 0);
        renderEncoder.setVertexBuffer(instances.buffer, offset: 0, index: 1)
        
        var vpMatrix = projectionMatrix * viewMatrix
        renderEncoder.setVertexBytes(&vpMatrix, length: MemoryLayout<float4x4>.stride, index: 2);
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cubeMesh.vertexCount, instanceCount: instances.data.count)
        
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

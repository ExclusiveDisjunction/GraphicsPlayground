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
    init?(_ device: MTLDevice, data: [MeshInstance] = [.init()] ) {
        self.data = data;
        self.buffer = Self.createBuffer(device, count: data.count);
        self.device = device;
    }
    
    @ObservationIgnored private var device: MTLDevice;
    fileprivate var data: [MeshInstance];
    @ObservationIgnored fileprivate var buffer: MTLBuffer?;
    
    private static func createBuffer(_ device: MTLDevice, count: Int) -> MTLBuffer? {
        guard count != 0 else {
            return nil;
        }
        
        let bufferSize = MemoryLayout<float4x4>.stride * count;
        guard let instanceBuffer = device.makeBuffer(length: bufferSize, options: []) else {
            return nil;
        }
        
        return instanceBuffer;
    }
    private func resizeBuffer() {
        self.buffer = Self.createBuffer(device, count: self.data.count)
    }
    
    var instances: [MeshInstance] {
        data
    }
    
    func addInstance() {
        data.append(.init());
        resizeBuffer()
    }
    func removeInstance(_ id: MeshInstance.ID) {
        data.removeAll(where: { $0.id == id } )
        resizeBuffer()
    }
    func removeInstances(_ id: Set<MeshInstance.ID>) {
        data.removeAll(where: { id.contains($0.id) } )
        resizeBuffer()
    }
}

final class CubeRender : NSObject, MTKViewDelegate {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    var depthStencilState: MTLDepthStencilState;
    var depthTexture: MTLTexture?;
    
    var cubeMesh: CubeMesh;
    var instances: CubeInstanceManager;
    var camera: CameraController;
    var projectionMatrix: float4x4;
    
    init(_ device: MTLDevice, instances: CubeInstanceManager, camera: CameraController) throws(MissingMetalComponentError) {
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw .commandQueue
        }
        self.commandQueue = commandQueue
        
        do {
            self.pipeline = try Self.buildPipeline(device: self.device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        do {
            self.cubeMesh = try CubeMesh(device)
        }
        catch let e {
            throw e
        }
        
        self.camera = camera
        
        self.projectionMatrix = float4x4(perspectiveFov: .pi / 3, aspectRatio: 1, nearZ: 0.1, farZ: 100)
        self.instances = instances
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            throw .depthStencil
        }
        
        self.depthStencilState = depthStencilState;
        
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width / size.height)
        self.projectionMatrix = float4x4(perspectiveFov: .pi / 3, aspectRatio: aspect, nearZ: 0.1, farZ: 100)
        
        let width = size.width == 0 ? 1 : size.width;
        let height = size.height == 0 ? 1 : size.height;
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(width),
            height: Int(height),
            mipmapped: false
        )
        desc.usage = .renderTarget
        desc.storageMode = .private
        self.depthTexture = device.makeTexture(descriptor: desc)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            print("no current drawable");
            return;
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("no command buffer could be made")
            return
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("no render pass descriptor could be found");
            return;
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.3, 0.3, 0.3, 1);
        renderPassDescriptor.colorAttachments[0].loadAction = .clear;
        renderPassDescriptor.colorAttachments[0].storeAction = .store;
        
        if let depth = depthTexture {
            renderPassDescriptor.depthAttachment.texture = depth
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
            renderPassDescriptor.depthAttachment.clearDepth = 1.0
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("unable to create the render encoder")
            return;
        }
        
        // This is required so the cube instances can be copied over.
        guard let instancesBuffer = instances.buffer else {
            // Just close out the render so it will clear the screen
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return;
        }
        
        let instanceMatrices = instances.data.map { $0.transform.modelMatrix };
        memcpy(instancesBuffer.contents(), instanceMatrices, MemoryLayout<float4x4>.stride * instanceMatrices.count);
        
        var viewMatrix = camera.cameraMatrix;
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(cubeMesh.buffer, offset: 0, index: 0);
        renderEncoder.setVertexBuffer(instancesBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.stride, index: 2);
        renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.stride, index: 3); //CHANGE, moved the matrices into the GPU directly
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cubeMesh.count, instanceCount: instances.data.count)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        
        guard  let vertexFunction = library.makeFunction(name: "simple3dVertex") else {
            throw MissingMetalComponentError.libraryFunction("simple3dVertex")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "simple3dFragment") else {
            throw MissingMetalComponentError.libraryFunction("simple3dFragment")
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

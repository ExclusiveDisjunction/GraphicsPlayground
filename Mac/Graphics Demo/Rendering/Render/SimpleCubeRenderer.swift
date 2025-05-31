//
//  SimpleCubeRenderer.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import SwiftUI
import Metal
import MetalKit

enum MissingMetalComponentError : Error {
    case commandQueue
    case pipeline((any Error)? = nil)
    case mesh(String)
    case depthStencil
    case defaultLibrary
    case libraryFunction(String) //Its name
    case buffer
    
    var description: String {
        let result = "the following component could not be made: "
        let name = switch self {
            case .commandQueue: "Command Queue"
            case .pipeline(let err):
                if let err = err {
                    "Pipeline with error \(err)"
                }
                else {
                    "Pipeline"
                }
            case .mesh(let name): "Mesh \"\(name)\""
            case .depthStencil: "Depth Stencil"
            case .defaultLibrary: "Default Library"
            case .libraryFunction(let name): "Library function \"\(name)\""
            case .buffer: "Buffer"
        };
        
        return result + name;
    }
}

final class SimpleCubeRenderer : NSObject, MTKViewDelegate {
    var device: MTLDevice;
    var commandQueue: MTLCommandQueue;
    var pipeline: MTLRenderPipelineState;
    var depthStencilState: MTLDepthStencilState;
    var depthTexture: MTLTexture?;
    
    var cubeMesh: CubeMesh;
    var transform: StandardTransformations;
    var cubeBuffer: MTLBuffer;
    var camera: CameraController;
    var projectionMatrix: float4x4;
    
    init(_ device: MTLDevice, transform: StandardTransformations, camera: CameraController) throws(MissingMetalComponentError) {
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw .commandQueue
        }
        self.commandQueue = commandQueue
        
        do {
            self.pipeline = try Self.buildPipeline(device: device)
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
            throw e;
        }
        
        guard let buffer = device.makeBuffer(length: MemoryLayout<float4x4>.stride) else {
            throw .buffer
        }
        self.cubeBuffer = buffer
        
        self.camera = camera
        self.transform = transform
        
        self.projectionMatrix = Self.makePerspective(aspectRatio: 1)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            throw .depthStencil
        }
        self.depthStencilState = depthStencilState
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width / size.height)
        self.projectionMatrix = Self.makePerspective(aspectRatio: aspect)
        
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
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("Internal needed components not present")
            return
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
            print("unable to create render encoder")
            return;
        }
    
        let instanceMatrix = transform.modelMatrix;
        memcpy(cubeBuffer.contents(), [instanceMatrix], MemoryLayout<float4x4>.stride)
        
        var viewMatrix = camera.cameraMatrix
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(cubeMesh.buffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(cubeBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.stride, index: 2);
        renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.stride, index: 3);
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cubeMesh.count, instanceCount: 1)
        
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
    
    static func makePerspective(fov: Float = .pi / 3, aspectRatio: Float, nearZ: Float = 0.1, farZ: Float = 100) -> float4x4 {
        float4x4(perspectiveFov: fov, aspectRatio: aspectRatio, nearZ: nearZ, farZ: farZ)
    }
}

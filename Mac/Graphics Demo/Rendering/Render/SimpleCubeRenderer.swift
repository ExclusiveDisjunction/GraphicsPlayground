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

final class SimpleCubeRenderer : RendererBasis3d, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;
    
    var cubeMesh: CubeMesh;
    var transform: StandardTransformations;
    /// The buffer for the cube's model matrix.
    var cubeBuffer: MTLBuffer;
    var camera: CameraController;
    
    init(_ device: MTLDevice, transform: StandardTransformations, camera: CameraController) throws(MissingMetalComponentError) {
        do {
            self.pipeline = try Self.buildPipeline(device: device)
            self.cubeMesh = try CubeMesh(device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        guard let buffer = device.makeBuffer(length: MemoryLayout<float4x4>.stride) else {
            throw .buffer
        }
        self.cubeBuffer = buffer
        
        self.camera = camera
        self.transform = transform
    
        try super.init(device)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.updateMTKView(view, size: size)
    }
    
    func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: commandQueue) else {
            return
        }
        
        context.setColorAttachments()
        context.setDepthTexture(depthTexture)
        
        guard let renderEncoder = context.makeEncoder() else {
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
        context.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        return try Self.makeSimplePipeline(device, vertex: "simple3dVertex", fragment: "simple3dFragment")
    }
}

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
import ExdisjGraphics

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

final class CubeRender : RendererBasis3d, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;
    
    var cubeMesh: CubeMesh;
    var instances: CubeInstanceManager;
    var camera: CameraController;
    
    init(_ device: MTLDevice, instances: CubeInstanceManager, camera: CameraController) throws(MissingMetalComponentError) {
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
        
        self.camera = camera
        self.instances = instances
        
        try super.init(device)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.updateMTKView(view, size: size)
    }
    
    func draw(in view: MTKView) {
        guard let context = FrameDrawContext(view: view, queue: commandQueue) else {
            return;
        }
        
        context.setColorAttachments()
        context.setDepthTexture(depthTexture)
        
        guard let renderEncoder = context.makeEncoder() else {
            print("unable to create the render encoder")
            return;
        }
        
        // This is required so the cube instances can be copied over.
        if let instancesBuffer = instances.buffer {
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
        }
        
        renderEncoder.endEncoding()
        context.commit()
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        return try self.makeSimplePipeline(device, vertex: "simple3dVertex", fragment: "simple3dFragment")
    }
}

//
//  HompageRender.swift
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

import SwiftUI
import Metal
import MetalKit

final class HomepageRender : RendererBasis3d, MTKViewDelegate {
    var pipeline: MTLRenderPipelineState;
    
    var frame: Int32 = 0;
    var mesh: PyramidMesh;
    var instances: [float4x4];
    var buffer: MTLBuffer;
    var camera: float4x4
    
    override init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        do {
            self.pipeline = try Self.buildPipeline(device: device)
            self.mesh = try PyramidMesh(device)
        }
        catch let e as MissingMetalComponentError {
            throw e
        }
        catch let e {
            throw .pipeline(e)
        }
        
        self.instances = [
            .init(translation: .init(  0,  1, 0)) * .init(rotationZ: .pi),      //Top
            .init(translation: .init(  0, -1, 0)) * .init(rotationZ: .pi),      //Bottom
            .init(translation: .init(  1,  0, 0)) * .init(rotationZ: -.pi / 2), //Right
            .init(translation: .init( -1,  0, 0)) * .init(rotationZ: -.pi / 2)  //Left
        ]

        self.camera = CameraController(eye: .init(0, 0, 5), center: .init(0, 0, 0), up: .init(0, 1, 0)).cameraMatrix;
        guard let buffer = device.makeBuffer(length: MemoryLayout<float4x4>.stride * instances.count) else {
            throw .buffer
        }
        self.buffer = buffer
        
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
            print("unable to create render encoder")
            return;
        }
        
        let angle = Float(frame) / 60 / (.pi / 8); //Every 60 frames, it will go pi/8 radians around. This is the central axis.
        let xAngle = Float(frame) / 120 / (.pi / 8); //The angle for rotating around the perpendicular axis.
        let tmpRot = float4x4(rotationZ: .pi); //A matrix used to rotate the rotation matrix 90 degrees, to keep it aligned properly.
        var rotMatrix = float4x4(rotation: .init(xAngle, -angle, 0)); //The matrix representing the current rotation standpoint.
        let finals = instances.map {
            let result = $0 * rotMatrix;
            rotMatrix *= tmpRot;
            
            return result;
        };
        
        memcpy(buffer.contents(), finals, MemoryLayout<float4x4>.stride * finals.count)
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(mesh.buffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&projectionMatrix, length: MemoryLayout<float4x4>.stride, index: 2);
        renderEncoder.setVertexBytes(&camera, length: MemoryLayout<float4x4>.stride, index: 3);
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.count, instanceCount: instances.count)
        
        renderEncoder.endEncoding()
        context.commit()
        
        frame += 1;
    }
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState {
        return try Self.makeSimplePipeline(device, vertex: "simple3dVertex", fragment: "simple3dFragment")
    }
}

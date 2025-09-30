//
//  RenderingBasis.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 6/2/25.
//

import MetalKit
import Metal

/// A base class that can be used to assist with building renderers.
open class RendererBasis : NSObject {
    /// The attached device
    public let device: MTLDevice;
    /// The attached command queue
    public let commandQueue: MTLCommandQueue;
    
    /// Constructs the required elements, and throws an error if something could not be created.
    public init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        self.device = device;
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw .commandQueue
        }
        self.commandQueue = commandQueue
        
        super.init()
    }
    
    /// Creates a matrix representing the perspective matrix, given specific values.
    public static func createPerspective(fov: Float = .pi / 3, aspect: Float, nearZ: Float = 0.1, farZ: Float = 100) -> float4x4 {
        float4x4(perspectiveFov: fov, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
    }
    
    /// Creates a pipleine using `bgra8Unorm` for pixel format, and `depth32Float` for the depth pixel format. It will create the metal functions with the specified names.
    public static func makeSimplePipeline(_ device: MTLDevice, vertex: String, fragment: String, is2d: Bool = false) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        guard let library = device.makeDefaultLibrary() else {
            throw MissingMetalComponentError.defaultLibrary
        }
        
        pipelineDescriptor.vertexFunction = try Self.getMetalFunction(library, name: vertex)
        pipelineDescriptor.fragmentFunction = try Self.getMetalFunction(library, name: fragment)
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
        if !is2d {
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        }
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    /// Obtains a function out of the metal library, throwing `MissingMetalComponentError.libraryFunction()` if it could not be found.
    public static func getMetalFunction(_ library: MTLLibrary, name: String) throws(MissingMetalComponentError) -> MTLFunction {
        guard let target = library.makeFunction(name: name) else {
            throw MissingMetalComponentError.libraryFunction(name)
        }
        
        return target;
    }
}

/// A base class that can be used to assist with building renderers. This one specifically aids with 3d rendering.
open class RendererBasis3d : RendererBasis {
    private var _depthTexture: MTLTexture?;
    
    /// The attached depth stencil state for 3d rendering
    public  let depthStencilState: MTLDepthStencilState;
    /// The depth texture used to aid with 3d rendering
    public var depthTexture: MTLTexture? { _depthTexture }
    
    /// The projection matrix used for transformations.
    public var projectionMatrix: float4x4;
    
    /// Constructs the required elements, and throws an error if something could not be created.
    public override init(_ device: MTLDevice) throws(MissingMetalComponentError) {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            throw .depthStencil
        }
        
        self.depthStencilState = depthStencilState;
        self.projectionMatrix = Self.createPerspective(aspect: 1)
        
        try super.init(device)
    }
    
    /// Updates the projection matrix and the 3d texture.
    public func updateMTKView(_ view: MTKView, size: CGSize) {
        let width = size.width == 0 ? 1 : size.width;
        let height = size.height == 0 ? 1 : size.height;
        
        self.projectionMatrix = Self.createPerspective(aspect: Float(width / height))
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(width),
            height: Int(height),
            mipmapped: false
        )
        desc.usage = [.shaderRead, .renderTarget]
        desc.storageMode = .memoryless
        self._depthTexture = device.makeTexture(descriptor: desc)
    }
}

/// A wrapper to help with setting up and completing a frame draw.
public struct FrameDrawContext : ~Copyable {
    /// Attempts to extract information out of the `view` and `queue` to start the frame drawing process. This returns `nil` if something is missing.
    @MainActor
    public init?(view: MTKView, queue: MTLCommandQueue) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = queue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return nil;
        }
        
        self.drawable = drawable
        self.commandBuffer = commandBuffer
        self.renderPassDescriptor = renderPassDescriptor
    }
    
    /// The drawable context
    public let drawable: CAMetalDrawable;
    /// The command buffer
    public let commandBuffer: MTLCommandBuffer;
    /// The render pass descriptor for creating a command encoder.
    public let renderPassDescriptor: MTLRenderPassDescriptor;
    
    /// Sets the color attachments for the `renderPassDescriptor`.
    public func setColorAttachments(bk: SIMD3<Double> = .init(0.3, 0.3, 0.3), load: MTLLoadAction = .clear, store: MTLStoreAction = .store) {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(bk.x, bk.y, bk.z, 1);
        renderPassDescriptor.colorAttachments[0].loadAction = load;
        renderPassDescriptor.colorAttachments[0].storeAction = store;
    }
    
    /// If a texture is provided, it will store it in the `renderPassDescriptor`.
    public func setDepthTexture(_ texture: MTLTexture?, load: MTLLoadAction = .clear, store: MTLStoreAction = .dontCare, colorDepth: Float = 1.0) {
        if let texture = texture {
            renderPassDescriptor.depthAttachment.texture = texture
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .dontCare
            renderPassDescriptor.depthAttachment.clearDepth = 1.0
        }
    }
    
    /// Uses the `renderPassDescriptor` and `commandBuffer` to create a command encoder.
    public func makeEncoder() -> MTLRenderCommandEncoder? {
        return commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    }
    
    /// Presents the `drawable` to the command buffer, and commits on the command buffer.
    public consuming func commit() {
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

//
//  Renderer.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import Metal;
import MetalKit;
import Foundation;
import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
#else
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

protocol RendererBasis : NSObject, MTKViewDelegate {
    init?(_ for: MetalView<Self>);
    
    static func buildPipeline(device: MTLDevice) throws -> MTLRenderPipelineState?;
}

struct MetalView<T> : PlatformViewRepresentable where T: RendererBasis {
    func makeCoordinator() -> T {
        guard let renderer = T(self) else {
            fatalError("Unable to get renderer");
        }
        
        return renderer
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> MTKView {
        self.createView(context: context)
    }
    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.delegate = context.coordinator;
        nsView.drawableSize = nsView.frame.size;
    }
    #elseif os(iOS)
    func makeUIView(context: Context) -> MTKView {
        self.createView(context: context)
        
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.delegate = context.coordinator;
        uiView.drawableSize = uiView.frame.size;
    }
    #endif
    
    private func createView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero);
        mtkView.delegate = context.coordinator;
        mtkView.preferredFramesPerSecond = 60;
        mtkView.enableSetNeedsDisplay = true;
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false;
        mtkView.drawableSize = mtkView.frame.size;
        
        return mtkView;
    }
}

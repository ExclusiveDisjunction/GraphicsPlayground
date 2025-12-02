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

public struct MetalView<T> : NSViewRepresentable where T: MTKViewDelegate {
    public init(_ coord: T, device: MTLDevice, is2d: Bool = false) {
        self.coord = coord;
        self.device = device;
        self.is2d = is2d;
    }
    private let device: MTLDevice;
    private let coord: T;
    private let is2d: Bool;
    
    public func makeCoordinator() -> T {
        return coord;
    }
    
    #if os(macOS)
    public func makeNSView(context: Context) -> MTKView {
        self.makeView(context: context)
    }
    public func updateNSView(_ nsView: MTKView, context: Context) {
        self.updateView(nsView, context: context)
    }
    #elseif os(iOS)
    public func makeUIView(context: Context) -> MTKView {
        self.makeView(context: context)
    }
    public func updateUIView(_ uiView: MTKView, context: Context) {
        self.updateView(uiView, context: context)
    }
    #endif
    
    private func makeView(context: Context) -> MTKView {
        let mtkView = MTKView();
        mtkView.delegate = context.coordinator;
        mtkView.autoResizeDrawable = true;
        mtkView.enableSetNeedsDisplay = true;
        mtkView.isPaused = false;
        
        mtkView.device = device;
        
        mtkView.framebufferOnly = false;
        mtkView.drawableSize = mtkView.frame.size;
        if !is2d {
            mtkView.depthStencilPixelFormat = .depth32Float
        }
        
        return mtkView;
    }
    private func updateView(_ view: MTKView, context: Context) {
        view.drawableSize = view.frame.size;
    }
}

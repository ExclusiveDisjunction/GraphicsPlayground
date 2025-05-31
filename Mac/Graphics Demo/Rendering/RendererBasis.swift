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

struct MetalView<T> : NSViewRepresentable where T: MTKViewDelegate {
    init(_ coord: T, device: MTLDevice) {
        self.coord = coord;
        self.device = device;
    }
    private let device: MTLDevice;
    private let coord: T;
    
    func makeCoordinator() -> T {
        return coord;
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView();
        mtkView.delegate = context.coordinator;
        mtkView.preferredFramesPerSecond = 60;
        mtkView.enableSetNeedsDisplay = false;
        mtkView.isPaused = false;
        
        mtkView.device = device;
        
        mtkView.framebufferOnly = false;
        mtkView.drawableSize = mtkView.frame.size;
        mtkView.depthStencilPixelFormat = .depth32Float
        
        return mtkView;
    }
    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.drawableSize = nsView.frame.size;
    }
}

//
//  CameraMetalView.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 6/1/25.
//

import Metal;
import MetalKit;
import Foundation;
import SwiftUI

struct CameraMetalView<T> : View where T: MTKViewDelegate {
    init(_ coord: T, device: MTLDevice, camera: CameraController) {
        self.coord = coord;
        self.device = device;
        self.camera = camera;
    }
    private let device: MTLDevice;
    private let coord: T;
    private let camera: CameraController;
    
    var body: some View {
        MetalView(coord, device: device)
            .focusable()
            .onKeyPress{ key in
                let by: SIMD3<Float>;
                let fac: Float = 0.05
                switch key.key {
                    case .init("w"):
                        by = camera.forward;
                    case .init("s"):
                        by = camera.reverse;
                    case .init("a"):
                        by = camera.left;
                    case .init("d"):
                        by = camera.right;
                    case .upArrow:
                        by = camera.up;
                    case .downArrow:
                        by = -camera.up;
                    case .rightArrow:
                        camera.up += (camera.right * fac);
                        return .handled;
                    case .leftArrow:
                        camera.up += (camera.left * fac);
                        return .handled;
                    default:
                        return .ignored
                }
                
                camera.eye += by * fac;
                
                return .handled
            }
    }
}

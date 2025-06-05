//
//  GridRenderHomepage.swift
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

import SwiftUI
import Metal
import ExdisjGraphics

struct GridRenderHomepage : View {
    
    init() {
        let camera = CameraController();
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        
        self.camera = camera
        self.device = device;
        do {
            self.render = try InfiniteGridRenderer(device, camera: camera)
        }
        catch let e {
            fatalError(e.description)
        }
    }
    
    @State private var showInspect: Bool = false;
    @State private var device: MTLDevice;
    @Bindable private var camera: CameraController;
    private var render: InfiniteGridRenderer;
    
    var body: some View {
        CameraMetalView(render, device: device, camera: camera)
            .padding()
            .inspector(isPresented: $showInspect) {
                ScrollView {
                    CameraEdit(control: camera)
                }.padding()
            }.toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showInspect.toggle() } ) {
                        Label(showInspect ? "Hide Inspector" : "Show Inspector", systemImage: "sidebar.right")
                    }
                }
            }
    }
}

#Preview {
    GridRenderHomepage()
}

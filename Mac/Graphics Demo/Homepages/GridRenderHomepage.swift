//
//  GridRenderHomepage.swift
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

import SwiftUI
import Metal

struct GridRenderHomepage : View {
    
    init() {
        let camera = CameraController();
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        
        self.camera = camera
        self.device = device;
        do {
            self.render = try GridRenderer(device, camera: camera)
        }
        catch let e {
            fatalError(e.description)
        }
    }
    
    @State private var showInspect: Bool = false;
    @State private var device: MTLDevice;
    @Bindable private var camera: CameraController;
    private var render: GridRenderer;
    
    var body: some View {
        MetalView(render, device: device)
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

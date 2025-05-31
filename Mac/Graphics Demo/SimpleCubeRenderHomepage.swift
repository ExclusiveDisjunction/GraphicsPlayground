//
//  SimpleCubeRenderHomepage.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import SwiftUI
import Metal

struct SimpleCubeRenderHomepage : View {
    init() {
        let camera = CameraController();
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        
        self.camera = camera
        self.device = device
        let transform = StandardTransformations();
        self.trans = transform;
        do {
            self.render = try SimpleCubeRenderer(device, transform: transform, camera: camera)
        }
        catch let e {
            fatalError(e.description)
        }
    }
    
    @State private var showInspect = false;
    @State private var device: MTLDevice;
    @Bindable private var trans: StandardTransformations;
    @Bindable private var camera: CameraController;
    private var render: SimpleCubeRenderer;
    
    @ViewBuilder
    private var inspectorContent: some View {
        TabView {
            Tab("Camera", systemImage: "rectangle") {
                ScrollView {
                    Form {
                        Float3ModifySection(x: $camera.position.x, y: $camera.position.y, z: $camera.position.z, label: "Position")
                        
                        Section(header: Text("Rotation")) {
                            BetterSlider(to: $camera.rotation.x, label: "α")
                            BetterSlider(to: $camera.rotation.y, label: "β")
                            BetterSlider(to: $camera.rotation.z, label: "γ")
                        }
                        
                    }.padding()
                }
            }
            Tab("Object", systemImage: "pencil") {
                ScrollView {
                    StdTransEditor(trans)
                }
            }
        }
    }
    
    var body: some View {
        MetalView(render, device: device)
            .inspector(isPresented: $showInspect) {
                inspectorContent
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showInspect.toggle() } ) {
                        Label(showInspect ? "Hide Inspector" : "Show Inspector", systemImage: "sidebar.right")
                    }
                }
            }
    }
}

#Preview {
    SimpleCubeRenderHomepage()
}

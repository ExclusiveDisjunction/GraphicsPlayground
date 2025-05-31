//
//  ContentView.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import SwiftUI
import SwiftData
import Metal;

struct ContentView: View {
    init() {
        let camera = CameraController();
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let instances = CubeInstanceManager(device),
              let render = CubeRender(device, instances: instances, camera: camera) else {
            fatalError()
        }
        
        self.camera = camera
        self.device = device
        self.instances = instances
        self.render = render
    }
    @State private var showInspect = false;
    @State private var selected: CubeInstance.ID?;
    @State private var device: MTLDevice;
    @Bindable private var instances: CubeInstanceManager;
    @Bindable private var camera: CameraController;
    private var render: CubeRender;
    
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
                        
                    }
                }
            }
            Tab("Object", systemImage: "pencil") {
                VStack {
                    if let id = selected, let cube = instances.instances.first(where: { $0.id == id }) {
                        ScrollView {
                            CubeModifier(cube)
                        }
                    }
                    else {
                        Text("Select an object to modify")
                            .italic()
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            HStack {
                Button(action: {
                    withAnimation {
                        instances.addInstance()
                    }
                }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    if let id = selected {
                        withAnimation {
                            instances.removeInstance(id)
                        }
                    }
                }) {
                    Image(systemName: "trash")
                }
            }
            
            List(instances.instances, selection: $selected) { cube in
                Text("Cube")
            }
        } detail: {
            MetalView<CubeRender>(render, device: device)
                .padding()
                .inspector(isPresented: $showInspect) {
                    inspectorContent
                }.inspectorColumnWidth(ideal: 250)
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
    ContentView()
}

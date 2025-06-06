//
//  ContentView.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import SwiftUI
import SwiftData
import Metal;
import ExdisjGraphics

struct CubeRenderHomepage: View {
    init() {
        let camera = CameraController();
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let instances = CubeInstanceManager(device) else {
            fatalError()
        }
        
        self.camera = camera
        self.device = device
        self.instances = instances
        do {
            self.render = try CubeRender(device, instances: instances, camera: camera)
        }
        catch let e {
            fatalError(e.description)
        }
    }
    @State private var showInspect = false;
    @State private var selected: MeshInstance.ID?;
    @State private var device: MTLDevice;
    @Bindable private var instances: CubeInstanceManager;
    @Bindable private var camera: CameraController;
    private var render: CubeRender;
    
    @ViewBuilder
    private var inspectorContent: some View {
        TabView {
            Tab("Camera", systemImage: "rectangle") {
                ScrollView {
                    CameraEdit(control: camera)
                }
            }
            Tab("Object", systemImage: "pencil") {
                VStack {
                    if let id = selected, let cube = instances.instances.first(where: { $0.id == id }) {
                        ScrollView {
                            StdTransEditor(cube.transform)
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
    CubeRenderHomepage()
}

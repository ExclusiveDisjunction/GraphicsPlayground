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
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError()
        }
        
        guard let instances = CubeInstanceManager(device) else {
            fatalError()
        }
        
        guard let render = CubeRender(device, instances: instances) else {
            fatalError()
        }
        
        self.device = device
        self.instances = instances
        self.render = render
    }
    @State private var showInspect = false;
    @State private var selected: CubeInstance.ID?;
    @State private var device: MTLDevice;
    @Bindable private var instances: CubeInstanceManager;
    private var render: CubeRender;
    
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
                    if let id = selected, let cube = instances.instances.first(where: { $0.id == id }) {
                        CubeModifier(cube)
                    }
                    else {
                        Text("Select an object to modify")
                            .italic()
                    }
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

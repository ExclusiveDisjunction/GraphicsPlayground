//
//  ContentView.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showInspect = false;
    @State private var selected: CubeInstance.ID?;
    @State private var instances: [CubeInstance] = [];
    
    var body: some View {
        NavigationSplitView {
            HStack {
                Button(action: { }) {
                    Image(systemName: "plus")
                }
                Button(action: { }) {
                    Image(systemName: "trash")
                }
            }
            
            List(instances, selection: $selected) { cube in
                Text("Cube")
            }
        } detail: {
            MetalView<CubeRender>()
                .padding()
                .inspector(isPresented: $showInspect) {
                    if let id = selected, let cube = instances.first(where: { $0.id == id }) {
                        
                    }
                    else {
                        Text("Select an object to modify")
                            .italic()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  FlowField
//
//  Created by Hollan Sellars on 11/8/25.
//

import SwiftUI

struct ContentView: View {
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("no graphics?")
        }
        self.device = device
        
        do {
            self.render = try VectorRenderer(device, sizeX: 10, sizeY: 10)
        }
        catch let e {
            fatalError("unable to open due to \(e)")
        }
    }
    
    @State private var device: MTLDevice;
    @State private var render: VectorRenderer;
    
    var body: some View {
        VStack {
            MetalView(render, device: device)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

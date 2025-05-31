//
//  TriangleRenderHomepage.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import SwiftUI
import Metal

struct TriangleRenderHomepage : View {
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No device?")
        }
        self.device = device;
        
        do {
            self.render = try TriangleRender(device);
            self.errorMsg = nil;
        }
        catch let e {
            self.render = nil;
            self.errorMsg = e.description;
        }
    }
    
    @State private var device: MTLDevice;
    @State private var errorMsg: String?;
    private var render: TriangleRender?;
    
    var body: some View {
        if let render = render {
            MetalView(render, device: device, is2d: true)
                .padding()
        }
        else if let err = errorMsg {
            VStack {
                Text("The renderer could not be created")
                    .font(.title2)
                Text("Error: \(err)")
            }.padding()
        }
        else {
            VStack {
                Text("Internal error!")
                Text("No renderer was made, and no error message was resulted either")
            }.padding()
        }
    }
}

#Preview {
    TriangleRenderHomepage()
}

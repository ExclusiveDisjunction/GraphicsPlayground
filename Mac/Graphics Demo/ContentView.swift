//
//  ContentView.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import SwiftUI
import ExdisjGraphics

enum Renderers {
    case homepage(HomepageRender)
    case triangle(TriangleRender)
    case simpleCube(SimpleCubeRenderer)
    case manyCube(CubeRender)
    case gridDemo(GridRenderer)
    
    var asChoice: RenderChoices {
        switch self {
            case .homepage(_): .homepage
            case .triangle(_): .triangle
            case .simpleCube(_): .simpleCube
            case .manyCube(_): .manyCube
            case .gridDemo(_): .gridDemo
        }
    }
    var features: [RenderAttachments] {
        switch self {
            case .homepage(_): [.mesh, .threeD]
            case .triangle(_): []
            case .simpleCube(_): [.camera, .mesh, .threeD]
            case .manyCube(_): [.camera, .mesh, .scene, .threeD]
            case .gridDemo(_): [.camera, .threeD]
        }
    }
    
    var asRenderer: RendererBasis {
        switch self {
            case .homepage(let h): h
            case .triangle(let t): t
            case .simpleCube(let c): c
            case .manyCube(let c): c
            case .gridDemo(let g): g
        }
    }
    @MainActor
    @ViewBuilder
    func renderView(_ device: MTLDevice) -> some View {
        switch self {
            case .homepage(let h):   MetalView(h, device: device)
            case .triangle(let t):   MetalView(t, device: device)
            case .simpleCube(let c): MetalView(c, device: device)
            case .manyCube(let c):   MetalView(c, device: device)
            case .gridDemo(let g):   MetalView(g, device: device)
        }
    }
    
    mutating func switchTo(_ choice: RenderChoices) {
        guard self.asChoice != choice else { return }
        
        
    }
}

enum RenderAttachments: String, CaseIterable, Identifiable {
    case scene = "Scene"
    case camera = "Camera"
    case mesh = "Mesh"
    case threeD = "3d"
    case colors = "Colors"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
            case .scene: "pencil.and.outline"
            case .camera: "camera.viewfinder"
            case .mesh: "grid"
            case .threeD: "shippingbox"
            case .colors: "eyedropper"
        }
    }
    var desc: String {
        switch self {
            case .scene: "The renderer supports custom scenes"
            case .camera: "The renderer supports a movable camera"
            case .mesh: "The renderer re-uses different meshes"
            case .threeD: "The renderer is 3d."
            case .colors: "The renderer supports custom coloring."
        }
    }
}

enum RenderChoices : String, CaseIterable, Identifiable {
    case homepage = "Homepage"
    case triangle = "2d Triangle"
    case simpleCube = "Simple Cube"
    case manyCube = "Cubes"
    case gridDemo = "Grid Demo"
    
    var id: Self { self }
    
    var desc: String {
        switch self {
            case .homepage: "A welcome screen to the app"
            case .triangle: "A quick demo of how the metal framework is built"
            case .simpleCube: "Display a single cube and a camera"
            case .manyCube: "Display many cubes that can each be transformed"
            case .gridDemo: "A demostration of the grid technology"
        }
    }
}

struct ContentView : View {
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("no graphics?")
        }
        self.device = device
        
        do {
            self.render = .homepage(try HomepageRender(device))
        }
        catch let e {
            fatalError("unable to open")
        }
    }
    
    @State private var device: MTLDevice;
    @State private var showInspector: Bool = false;
    @State private var render: Renderers;
    
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.dismiss) private var dismiss;
    
/*
 @ViewBuilder
 private var title: some View {
 GeometryReader { geometry in
 VStack {
 VStack {
 Text("Graphics Playground")
 .font(.title)
 Text("A simple project to demostrate Metal pipelines")
 .font(.subheadline)
 }.padding()
 .background(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
 .fill(.background.secondary.opacity(0.4))
 )
 }
 .frame(width: geometry.size.width, height: geometry.size.height)
 .multilineTextAlignment(.center)
 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
 }.padding()
 }
 */
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Scene")
                    .font(.title2)
                
                
                
            }.padding(.top)
        } detail: {
            render.renderView(device)
                .focusable()
        }.navigationSplitViewStyle(.prominentDetail)
            .inspector(isPresented: $showInspector) {
                
            }
            .inspectorColumnWidth(ideal: 200)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Label(showInspector ? "Hide Inspector" : "Show Inspector", systemImage: "sidebar.right")
                    }
                }
            }
        
        /*
         NavigationSplitView {
         options
         .background(Rectangle().fill(.background.secondary))
         .frame(width: 200)
         } detail: {
         title
         .background(makeRenderBackground)
         .navigationTitle("")
         }
         */
    }
}

#Preview {
    ContentView()
        .frame(width: 600, height: 500)
}

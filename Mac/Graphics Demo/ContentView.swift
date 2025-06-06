//
//  ContentView.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import SwiftUI
import ExdisjGraphics

enum RenderChoices : String, CaseIterable, Identifiable{
    case triangle = "2d Triangle"
    case simpleCube = "Simple Cube"
    case manyCube = "Cubes"
    case gridDemo = "Grid Demo"
    
    var id: String {
        switch self {
            case .triangle: "simpleTriangle"
            case .simpleCube: "simpleCubeRender"
            case .manyCube: "cubeRender"
            case .gridDemo: "gridDemo"
        }
    }
    
    var desc: String {
        switch self {
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
            self.render = try HomepageRender(device)
        }
        catch let e {
            print(e.description)
            self.render = nil;
        }
    }
    
    @State private var device: MTLDevice;
    private var render: HomepageRender?;
    
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.dismiss) private var dismiss;
    
    @ViewBuilder
    var makeRenderBackground: some View {
        if let render = render {
            MetalView(render, device: device)
        }
        else {
            Rectangle()
                .fill(.red)
        }
    }
    
    @ViewBuilder
    func choiceView(_ choice: RenderChoices) -> some View {
        VStack {
            HStack {
                Image(systemName: "arrow.right")
                Text(choice.rawValue)
                    .font(.headline)
                    .underline(true, color: .primary)
                Spacer()
            }
            HStack {
                Text(choice.desc)
                    .italic()
                Spacer()
            }
        }.padding(.bottom, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                openWindow(id: choice.id)
                dismiss()
            }
    }
    
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
    
    @ViewBuilder
    private var options: some View {
        ScrollView {
            VStack {
                Text("Demos")
                    .font(.title2)
                Divider().padding(.bottom, 3)
                ForEach(RenderChoices.allCases, id: \.id) { choice in
                    choiceView(choice)
                }
            }.padding()
        }
    }
    
    var body: some View {
        NavigationSplitView {
            options
                .background(Rectangle().fill(.background.secondary))
                .frame(width: 200)
        } detail: {
            title
                .background(makeRenderBackground)
                .navigationTitle("")
        }
    }
}

#Preview {
    ContentView()
}

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
            self.render = try VectorRenderer(device, qnty: SIMD2(40, 40), size: SIMD2(300, 300))
        }
        catch let e {
            fatalError("unable to open due to \(e)")
        }
    }
    
    @State private var device: MTLDevice;
    @State private var render: VectorRenderer;
    @State private var inspector = true;
    @State private var isEditing = false;
    
    var body: some View {
        VectorFieldView(render: render, device: device)
            .padding()
            .inspector(isPresented: $inspector) {
                ScrollView {
                    VStack {
                        HStack {
                            Text("Properties")
                                .font(.title2)
                            
                            Spacer()
                            
                            Button(isEditing ? "Save" : "Edit") {
                                
                            }.buttonStyle(.accessoryBar)
                        }
                        
                        Grid {
                            GridRow {
                                HStack {
                                    Text("Colors")
                                        .font(.headline)
                                    
                                    Spacer()
                                }.gridCellColumns(2)
                            }
                            
                            GridRow {
                                Text("Minimum:")
                                    .gridCellAnchor(.trailing)
                                
                                HStack {
                                    Text( "0x" + String(render.colors.minHex, radix: 16, uppercase: true))
                                    Color(cgColor: render.colors.minCGColor)
                                        .frame(width: 40, height: 40)
                                }.gridCellAnchor(.leading)
                            }
                            
                            GridRow {
                                Text("Maximum:")
                                    .gridCellAnchor(.trailing)
                                
                                HStack {
                                    Text( "0x" + String(render.colors.maxHex, radix: 16, uppercase: true))
                                    Color(cgColor: render.colors.maxCGColor)
                                        .frame(width: 40, height: 40)
                                }.gridCellAnchor(.leading)
                            }
                            
                            GridRow {
                                HStack {
                                    Text("Scale & Zoom")
                                        .font(.headline)
                                    
                                    Spacer()
                                }.gridCellColumns(2)
                            }
                            
                            GridRow {
                                HStack {
                                    Text("Shift:")
                                        .gridCellColumns(2)
                                    Spacer()
                                }
                            }
                            
                            GridRow {
                                Slider(value: $render.panX, in: -render.size.x...render.size.x) {
                                    Text("X:")
                                } minimumValueLabel: {
                                    Text(-render.size.x, format: .number.precision(.fractionLength(0)))
                                } maximumValueLabel: {
                                    Text(render.size.x, format: .number.precision(.fractionLength(0)))
                                }.gridCellColumns(2)
                            }
                            
                            GridRow {
                                Slider(value: $render.panY, in: -render.size.y...render.size.y) {
                                    Text("Y:")
                                } minimumValueLabel: {
                                    Text(-render.size.y, format: .number.precision(.fractionLength(0)))
                                } maximumValueLabel: {
                                    Text(render.size.y, format: .number.precision(.fractionLength(0)))
                                }.gridCellColumns(2)
                            }
                            
                            GridRow {
                                Slider(value: $render.zoom, in: 0.1...4) {
                                    Text("Zoom:")
                                } minimumValueLabel: {
                                    Text(0.1, format: .number.precision(.fractionLength(1)))
                                } maximumValueLabel: {
                                    Text(4, format: .number.precision(.fractionLength(1)))
                                } ticks: {
                                    SliderTick("1", 1.0)
                                    SliderTick("2", 2.0)
                                    SliderTick("3", 3.0)
                                }.gridCellColumns(2)
                            }
                        }
                        
                        
                        
                        Spacer()
                    }
                }.padding()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inspector.toggle()
                    } label: {
                        Label("Inspector", systemImage: "sidebar.right")
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}

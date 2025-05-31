//
//  CubeModifier.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/30/25.
//

import SwiftUI

struct BetterSlider : View {
    @Binding var to: Float;
    let min: Float;
    let max: Float;
    let label: String;
    
    var body: some View {
        TextField(label, value: $to, format: .number.precision(.fractionLength(2)))
    }
}

struct CubeModifier : View {
    @Bindable private var over: StandardTransformations;
    
    init(_ over: CubeInstance) {
        self.over = over.transform
    }
    
    var body: some View {
        VStack {
            Text("Cube")
                .font(.title3)
            
            Form {
                Section(header: Text("Position")) {
                    BetterSlider(to: $over.position.x, min: -10.0, max: 10.0, label: "X")
                    BetterSlider(to: $over.position.y, min: -10.0, max: 10.0, label: "Y")
                    BetterSlider(to: $over.position.z, min: -10.0, max: 10.0, label: "Z")
                }
                
                Section(header: Text("Rotation")) {
                    BetterSlider(to: $over.rotation.x, min: 0, max: 2.0 * .pi, label: "α")
                    BetterSlider(to: $over.rotation.y, min: 0, max: 2.0 * .pi, label: "β")
                    BetterSlider(to: $over.rotation.z, min: 0, max: 2.0 * .pi, label: "γ")
                }
                
                Section(header: Text("Scale")) {
                    BetterSlider(to: $over.scale.x, min: 0, max: 10.0, label: "X")
                    BetterSlider(to: $over.scale.y, min: 0, max: 10.0, label: "Y")
                    BetterSlider(to: $over.scale.z, min: 0, max: 10.0, label: "Z")
                }
            }
        }.padding()
    }
}

#Preview {
    let modify = CubeInstance();
    CubeModifier(modify)
}

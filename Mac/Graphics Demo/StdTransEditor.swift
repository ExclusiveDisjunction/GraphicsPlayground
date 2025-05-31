//
//  CubeModifier.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/30/25.
//

import SwiftUI

struct BetterSlider : View {
    @Binding var to: Float;
    /*
    let min: Float;
    let max: Float;
     */
    let label: String;
    
    var body: some View {
        TextField(label, value: $to, format: .number.precision(.fractionLength(2)))
    }
}

struct Float3ModifySection : View {
    @Binding var x: Float;
    @Binding var y: Float;
    @Binding var z: Float;
    let label: String;
    let xL: String = "X";
    let yL: String = "Y";
    let zL: String = "Z";
    
    var body: some View {
        Section(header: Text(label)) {
            BetterSlider(to: $x, label: xL)
            BetterSlider(to: $y, label: yL)
            BetterSlider(to: $z, label: xL)
        }
    }
    
}

struct StdTransEditor : View {
    @Bindable private var over: StandardTransformations;
    
    init(_ over: StandardTransformations) {
        self.over = over
    }
    
    var body: some View {
        Form {
            Float3ModifySection(x: $over.position.x, y: $over.position.y, z: $over.position.z, label: "Position")
            
            Section(header: Text("Rotation")) {
                BetterSlider(to: $over.rotation.x, label: "α")
                BetterSlider(to: $over.rotation.y, label: "β")
                BetterSlider(to: $over.rotation.z, label: "γ")
            }
            
            Float3ModifySection(x: $over.scale.x, y: $over.scale.y, z: $over.scale.z, label: "Scale")
        }.padding()
    }
}

#Preview {
    let modify = StandardTransformations();
    StdTransEditor(modify)
}

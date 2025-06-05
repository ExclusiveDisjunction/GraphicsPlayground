//
//  Tools.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 6/1/25.
//

import SwiftUI
import ExdisjGraphics

struct CameraEdit : View {
    @Bindable var control: CameraController;
    
    var body: some View {
        VStack {
            Text("Camera")
            
            Form {
                Float3ModifySection(x: $control.center.x, y: $control.center.y, z: $control.center.z, label: "Center")
                
                Float3ModifySection(x: $control.eye.x, y: $control.eye.y, z: $control.eye.z, label: "Eye")
                
                Float3ModifySection(x: $control.up.x, y: $control.up.y, z: $control.up.z, label: "Up")
            }
        }
    }
}

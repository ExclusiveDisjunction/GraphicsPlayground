//
//  ContentView.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MetalView<TriangleRender>().padding()
    }
}

#Preview {
    ContentView()
}

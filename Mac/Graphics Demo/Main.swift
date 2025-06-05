//
//  Graphics_DemoApp.swift
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

import SwiftUI
import SwiftData

@main
struct Graphics_DemoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                //.frame(width: 700, height: 500)
        }
        
        WindowGroup("Cubes", id: "cubeRender") {
            CubeRenderHomepage()
        }
        
        WindowGroup("Simple Cube", id: "simpleCubeRender") {
            SimpleCubeRenderHomepage()
        }
        
        WindowGroup("2d Triangle", id: "simpleTriangle") {
            TriangleRenderHomepage()
        }
        
        WindowGroup("Grid Demo", id: "gridDemo") {
            GridRenderHomepage()
        }
    }
}

//
//  MeshBasics.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

import simd
import Metal

/// A simple structure encoding a position and color.
public struct Vertex {
    /// The position of the point
    public var position: SIMD3<Float>
    /// The color of that point, or face. 
    public var color: SIMD3<Float>
}

/// A protocol representing an object to display.
/// A mesh is like a template, it can be used over and over. It has some internal dimensions, but this gets transformed & represented on the screen.
public protocol MeshBasis {
    /// A unique name used to identify the specific mesh.
    static var name: String { get }
    /// The buffer for the meshes' vertices.
    var buffer: MTLBuffer { get }
    /// The number of items stored in the buffer.
    var count: Int { get }
}
/// Represents a mesh that has vertices, and uses indexes to hold the valuesl
public protocol IndexBasedMesh : MeshBasis {
    /// The storage for the meshes'  indices.
    var indexBuffer: MTLBuffer { get }
    /// The number of indices.
    var indexCount: Int { get }
}

/// Represents a mesh that can be created 'context free'. Specifically, this means that the mesh is non-customizable, and just defaults to some configuration.
protocol PrimativeMesh : MeshBasis {
    /// Constructs the mesh, throwing an error if something is missing. Usually this will throw `.buffer` if there is an error.
    init(_ device: MTLDevice) throws(MissingMetalComponentError);
    
    /// Generates the `Vertex` instances required.
    static func generateVertices() -> [Vertex]
}
/// This is a primative mesh that is also index based.
protocol IndexBasedPrimativeMesh : PrimativeMesh, IndexBasedMesh {
    /// Creates the indices over the vertices required.
    static func generateIndices() -> [Int]
}

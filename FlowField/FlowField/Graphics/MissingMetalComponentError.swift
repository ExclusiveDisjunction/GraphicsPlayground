//
//  MissingMetalComponentError.swift
//  Graphics Demo
//
//  Created by Hollan Sellars on 6/4/25.
//

/// An error type that represents an issue when trying to make or obtain a metal component.
public enum MissingMetalComponentError : Error {
    case commandQueue
    case pipeline((any Error)? = nil)
    case mesh(String)
    case depthStencil
    case defaultLibrary
    case libraryFunction(String) //Its name
    case buffer
    case fence
    
    /// A string description of what is missing.
    public var description: String {
        let result = "the following component could not be made: "
        let name = switch self {
            case .commandQueue: "Command Queue"
            case .pipeline(let err):
                if let err = err {
                    "Pipeline with error \(err)"
                }
                else {
                    "Pipeline"
                }
            case .mesh(let name): "Mesh \"\(name)\""
            case .depthStencil: "Depth Stencil"
            case .defaultLibrary: "Default Library"
            case .libraryFunction(let name): "Library function \"\(name)\""
            case .buffer: "Buffer"
            case .fence: "Fence"
        };
        
        return result + name;
    }
}

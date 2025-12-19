//
//  Untitled.swift
//  FlowField
//
//  Created by Hollan Sellars on 11/8/25.
//

import Metal
import MetalKit
import simd

public class ParametricRenderer : VectorFieldRenderer, @unchecked Sendable {
    public init(_ device: MTLDevice, qnty: SIMD2<Int>, size: SIMD2<Float>) throws {
        try super.init(
            device,
            qnty: qnty,
            size: size,
            vectorSize: MemoryLayout<ParametricVector>.stride,
            positionFunc: "positionVectorsParametric",
            animateFunc: "animateVectorsParametric",
            transformFunc: "transformParametric"
        )
    }
}

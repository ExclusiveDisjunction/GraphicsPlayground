//
//  CartesianRenderer.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

import Metal
import MetalKit
import simd

public class CartesianRenderer : VectorFieldRenderer, @unchecked Sendable {
    public init(_ device: MTLDevice, qnty: SIMD2<Int>, size: SIMD2<Float>) throws {
        try super.init(
            device,
            qnty: qnty,
            size: size,
            vectorSize: MemoryLayout<CartesianVector>.stride,
            positionFunc: "positionVectorsCartesian",
            animateFunc: "animateVectorsCartesian",
            transformFunc: "transformCartesian"
        )
    }
}

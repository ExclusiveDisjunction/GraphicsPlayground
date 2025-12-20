//
//  VectorRendererProperties.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

import Observation
import simd

@Observable
public class VectorRendererProperties {
    public init(panX: Float, panY: Float) {
        //self.colors = ColorSchema(min: SIMD3(0.337255, 0.7568628, 0.9098039), max: SIMD3(0.462745, 0.337255, 0.9098039))
        self.zoom = 1;
        self.panX = panX;
        self.panY = panY;
    }
    
    //public var colors: ColorSchema;
    public var zoom: Float;
    public var panX: Float;
    public var panY: Float;
    
    public var zoomMatrix: float4x4 {
        float4x4(
            rows:[
                SIMD4(self.zoom, 0,         0, 0),
                SIMD4(0,         self.zoom, 0, 0),
                SIMD4(0,         0,         1, 0),
                SIMD4(0,         0,         0, 1)
            ]
        )
    }
    public var panMatrix: float4x4 {
        var result = matrix_identity_float4x4;
        result.columns.3 = SIMD4<Float>(self.panX, self.panY, 0.0, 1);
        
        return result
    }
}

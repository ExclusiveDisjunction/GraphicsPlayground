//
//  axis.metal
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

#include <metal_stdlib>
#include "metalBasic.h"
using namespace metal;

VertexOut vertex axisVertex(const device VertexIn* vertices [[buffer(0)]],
                            constant float4x4& perspective [[buffer(1)]],
                            constant float4x4& camera [[buffer(2)]],
                            uint vertexID [[vertex_id]]
                            ) {
    VertexOut out;
    VertexIn in = vertices[vertexID];
    float4 worldPosition = float4(in.position, 1.0);
    out.position = perspective * camera * worldPosition;
    out.color = in.color;
    
    return out;
}

float4 fragment axisFragment(VertexOut in [[stage_in]]) {
    return float4(in.color, 1.0);
}

//
//  simpleViewer.metal
//  FlowField
//
//  Created by Hollan Sellars on 12/2/25.
//

#include <metal_stdlib>
#include "../Headers/VectorRendering.h"
using namespace metal;


vertex OutputVector renderVectorBody(
    const device RenderableVector* instances [[buffer(0)]],
    const device VectorVertexContext& cx [[buffer(1)]],
    uint vertexId [[vertex_id]],
    uint instanceId [[instance_id]]
) {
    RenderableVector value = instances[instanceId];

    float2 pos;
    switch (vertexId) {
        case 0:
            pos = value.bottomLeft;
            break;
        case 1:
            pos = value.bottomRight;
            break;
        case 2:
            pos = value.topLeft;
            break;
        case 3:
            pos = value.topRight;
            break;
        default:
            pos = float2(0.0);
            break;
    }

    OutputVector out;
    out.pos = cx.transform * float4(pos, 0.0, 1.0);
    out.mag = value.mag;
    
    return out;
}

vertex OutputVector renderVectorPoint(
     const device RenderableVector* instances [[buffer(0)]],
     const device VectorVertexContext& cx [[buffer(1)]],
     uint vertexId [[vertex_id]],
     uint instanceId [[instance_id]]
) {
    RenderableVector value = instances[instanceId];

    float2 pos;
    switch (vertexId) {
        case 0:
            pos = value.t_left;
            break;
        case 1:
            pos = value.t_right;
            break;
        case 2:
            pos = value.t_top;
            break;
        default:
            pos = float2(0.0);
            break;
    }
    
    OutputVector out;
    out.pos = cx.transform * float4(pos, 0.0, 1.0);
    out.mag = value.mag;
    
    return out;
}

fragment float4 vectorFragment(
    OutputVector input [[stage_in]],
    constant ColorSchema& colors [[buffer(0)]]
) {
    float3 m = mix(colors.min, colors.max, input.mag);
    return float4(m, 1.0);
}

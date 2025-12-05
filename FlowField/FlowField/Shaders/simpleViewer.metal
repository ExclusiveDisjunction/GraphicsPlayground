//
//  simpleViewer.metal
//  FlowField
//
//  Created by Hollan Sellars on 12/2/25.
//

#include <metal_stdlib>
#include "common.h"
using namespace metal;

kernel void setupVectors(
    device FlowVector* instances [[buffer(0)]],
    const device VectorsSetupCx& cx [[buffer(1)]],
    uint instanceId [[thread_position_in_grid]]
) {
    // Determine the i, j values for the grid based on the step
    uint i = instanceId % cx.sizex;
    uint j = instanceId / cx.sizey;
    
    float2 pos = float2(float(i), float(j));
    
    instances[instanceId].tail = pos * cx.step;
    
    float2 diff = sin(pos) - instances[instanceId].tail;

    instances[instanceId].angMag = float2(
        sqrt(diff.x * diff.x + diff.y * diff.y),
        atan2(diff.y, diff.x)
    );
}

kernel void animateVectors(
    device FlowVector* instances [[buffer(0)]],
    const device VectorsSetupCx& cx [[buffer(1)]],
    uint instanceId [[thread_position_in_grid]]
) {
    instances[instanceId].angMag.x += M_PI_F / 16;
}

vertex OutputFlowVector transformVectorOutputs(
    const device FlowVector* instances [[buffer(0)]],
    const device float4x4& transform [[buffer(1)]],
    const device float& thickness [[buffer(2)]],
    uint vertexId [[vertex_id]],
    uint instanceId [[instance_id]]
) {
    FlowVector value = instances[instanceId];
    
    /*
        The vertex index goes from 0->4.
        If the vertex index is < 2, then it is the tail side of the quad.
        Otherwise, it is the tip side of the quad.
     
     */
    
    OutputFlowVector out;
    out.mag = value.angMag.y;
    float2 tip;
    {
        float angle = value.angMag.x;
        float mag = mix(0, 4, value.angMag.y);
        tip = value.tail + float2(cos(angle), sin(angle)) * mag;
    }
    
    // Now we determine the value offset of the thickness.
    float2 direction = normalize(tip - value.tail);
    float2 normal = float2(-direction.y, direction.x);
    float2 offset = normal * (thickness / 2.0);
    
    float2 pos;
    switch (vertexId) {
        case 0:
            pos = value.tail + offset;
            break;
        case 1:
            pos = value.tail - offset;
            break;
        case 2:
            pos = tip + offset;
            break;
        case 3:
            pos = tip - offset;
            break;
    }
    
    out.pos = transform * float4(pos, 0.0, 1.0);
    
    return out;
}

fragment float4 vectorFragment(
                               OutputFlowVector input [[stage_in]],
                               constant ColorSchema& colors [[buffer(0)]]) {
    float3 m = mix(colors.min, colors.max, input.mag);
    return float4(m, 1.0);
}

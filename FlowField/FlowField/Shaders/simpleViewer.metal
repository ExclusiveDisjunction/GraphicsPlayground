//
//  simpleViewer.metal
//  FlowField
//
//  Created by Hollan Sellars on 12/2/25.
//

#include <metal_stdlib>
#include "common.h"
using namespace metal;

vertex OutputFlowVector transformVectorOutputs(
    const device FlowVector* instances [[buffer(0)]],
    uint vertexId [[vertex_id]],
    uint instanceId [[instance_id]]
) {
    FlowVector value = instances[instanceId];
    
    OutputFlowVector out;
    out.mag = value.angMag.y;
    float2 pos;
    if (vertexId % 2 == 0) { // Tail
        pos = value.tail;
    }
    else { // Tip
        float angle = value.angMag.x;
        float mag = 0.1;
        pos = value.tail + float2(cos(angle), sin(angle)) * mag;
    }
    
    out.pos = float4(pos, 0.0, 1.0);
    
    return out;
}

fragment float4 vectorFragment(OutputFlowVector input [[stage_in]]) {
    float m = input.mag / 10.0;
    m = mix(0.5, 1.0, m);
    return float4(m, 0.0, 1.0 - m, 1.0);
}

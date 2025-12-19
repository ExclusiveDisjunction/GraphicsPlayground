//
//  tailtip.metal
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

#include <metal_stdlib>
#include "common.h"
using namespace metal;

kernel void positionVectorsCartesian(
     device CartesianVector* instances [[buffer(0)]],
     const device VectorSetupContext& cx [[buffer(1)]],
     uint instanceId [[thread_position_in_grid]]
) {
    uint i = instanceId % cx.sizex;
    uint j = instanceId / cx.sizex;
    
    float2 pos = float2(float(i), float(j));
    
    instances[instanceId].tail = pos * cx.step;
}

kernel void animateVectorsCartesian(
    device CartesianVector* instances [[buffer(0)]],
    const device VectorAnimateContext& cx [[buffer(1)]],
    uint instanceId [[thread_position_in_grid]]
) {
    CartesianVector target = instances[instanceId];
    
    instances[instanceId].tip = float2(
       sin(target.tail.x + cx.time) - cos(target.tail.y - cx.time),
       cos(target.tail.x - cx.time) - sin(target.tail.y + cx.time)
    );
}

kernel void transformCartesian(
   const device CartesianVector* input [[buffer(0)]],
   device RenderableVector* output [[buffer(1)]],
   const device TransformContext& context [[buffer(2)]],
   uint instanceId [[thread_position_in_grid]]
) {
    CartesianVector value = input[instanceId];
    float vecMag = length(value.tip);
    float mag = min(vecMag * 4, context.magnitude);
    float2 tip = value.tail + normalize(value.tip) * mag;
    
    // Now we determine the value offset of the thickness.
    float len = length(tip - value.tail);
    float2 direction = (len > 0.0001) ? (tip - value.tail) / len : float2(1, 0);
    float2 normal = float2(-direction.y, direction.x);
    float2 offset = normal * (context.thickness / 2.0);
    
    RenderableVector out;
    out.bottomLeft = value.tail - offset;
    out.bottomRight = value.tail + offset;
    out.topLeft = tip - offset;
    out.topRight = tip + offset;
    
    out.t_left = tip - (2 * offset);
    out.t_right = tip + (2 * offset);
    
    float h = 2.0 * sqrt(3.0) * length(offset);
    out.t_top = tip + direction * h;
    out.mag = vecMag;
    
    output[instanceId] = out;
}

//
//  parametric.metal
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

#include <metal_stdlib>
#include "../Headers/VectorRendering.h"
using namespace metal;

/// Assigns each vector to a specific position in the grid, based on its index location in said grid.
/// This should be called during first setup & during resizes.
/// This does not assign angles and magnitudes. For that, see `angleVectors`.
kernel void positionVectorsParametric(
    device ParametricVector* instances [[buffer(0)]],
    const device VectorSetupContext& cx [[buffer(1)]],
    uint instanceId [[thread_position_in_grid]]
) {
    // Determine the i, j values for the grid based on the step
    uint i = instanceId % cx.sizex;
    uint j = instanceId / cx.sizex;
    
    float2 pos = float2(float(i), float(j));
    
    instances[instanceId].tail = pos * cx.step;
}

/// Called once per frame; computes the vectors based on the position (x,y), and time (t).
kernel void animateVectorsParametric(
    device ParametricVector* instances [[buffer(0)]],
    const device VectorAnimateContext& cx [[buffer(1)]],
    uint instanceId [[thread_position_in_grid]]
) {
    instances[instanceId].angle = ((float)instanceId + cx.time) * (M_PI_F / 8);
    instances[instanceId].mag = sin(cx.time) * 4 + 10;
}

kernel void transformParametric(
    const device ParametricVector* input [[buffer(0)]],
    device RenderableVector* output [[buffer(1)]],
    const device TransformContext& context [[buffer(2)]],
    uint instanceId [[thread_position_in_grid]]
) {
    ParametricVector value = input[instanceId];
    
    float2 foundTip =  value.mag * float2(
        cos(value.angle),
        sin(value.angle)
    );
    float vecMag = length(foundTip);
    float mag = min(vecMag * 4, context.magnitude);
    vector_float2 tip = value.tail + normalize(foundTip) * mag;
    
    // Now we determine the value offset of the thickness.
    float len = length(tip - value.tail);
    float2 direction = (len > 0.0001) ? (tip - value.tail) / len : float2(1, 0);
    float2 normal = vector_float2(-direction.y, direction.x);
    float2 offset = normal * (context.thickness / 2.0);
    
    RenderableVector result;
    result.bottomLeft = value.tail - offset;
    result.bottomRight = value.tail + offset;
    result.topLeft = tip - offset;
    result.topRight = tip + offset;
    
    result.t_left = tip - (2 * offset);
    result.t_right = tip + (2 * offset);
    
    float h = 2.0 * sqrt(3.0) * length(offset);
    result.t_top = tip + direction * h;
    result.mag = vecMag;
    
    output[instanceId] = result;
}

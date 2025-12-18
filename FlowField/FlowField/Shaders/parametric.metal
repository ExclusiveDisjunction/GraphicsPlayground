//
//  parametric.metal
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

#include <metal_stdlib>
#include "common.h"
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
    instances[instanceId].angle = ((float)instanceId + cx.time) * (M_PI_F / 32);
    instances[instanceId].mag = sin(cx.time) * 4 + 5;
}

kernel void transformParametric(
    const device ParametricVector* input [[buffer(0)]],
    device RenderableVector* output [[buffer(1)]],
    const device float& thickness [[buffer(2)]],
    uint instanceId [[thread_position_in_grid]]
) {
    ParametricVector value = input[instanceId];
    float angle = value.angle;
    float mag = min (value.mag, 7.0 );
    float2 tip = value.tail + float2(cos(angle), sin(angle)) * mag;
    
    // Now we determine the value offset of the thickness.
    float len = length(tip - value.tail);
    float2 direction = (len > 0.0001) ? (tip - value.tail) / len : float2(1, 0);
    float2 normal = float2(-direction.y, direction.x);
    float2 offset = normal * (thickness / 2.0);
    
    RenderableVector out;
    out.bottomLeft = value.tail - offset;
    out.bottomRight = value.tail + offset;
    out.topLeft = tip - offset;
    out.topRight = tip + offset;
    
    out.t_left = tip - (2 * offset);
    out.t_right = tip + (2 * offset);
    
    /*
                            / |
                           /  |
                          /   |
        c= 4*|offset|    /    |  height = h
                        /     |
                       /      |
                      /       |
                     /        |
                     ---------
                      Width = 2 * |offset|
     
        c^2 = w^2 + h^2
        h^2 = c^2 - w^2
        h^2 = 16*|offset|^2 - 4 * |offset|^2
        h^2 = 12*|offset|^2
        h = 2*sqrt(3)*|offset|
     */
    
    /*
        Overall, I want the magnitude to be 90% of the entire figures shape.
     
        So, len = length(tip - tail) + h
            len = length(tip - tail) + (2 * sqrt(3) * magnitude(offset))
            0.9 * cell = sqrt((x - m * cos(angle))^2 + (y - m * sin(angle))^2) + (sqrt(3) * thickness))
            0.9 * cell - sqrt(3) * thickness = sqrt((x - m * cos(angle))^2 + (y - m * sin(angle))^2)
            (0.9 * cell - sqrt(3) * thicknes)^2 = (x - m * cos(angle))^2 + (y - m * sin(angle))^2
            
            To be continued...
     */
    
    float h = 2.0 * sqrt(3.0) * length(offset);
    out.t_top = tip + direction * h;
    out.mag = mag;
    
    output[instanceId] = out;
}

//
//  axis.metal
//  Graphics Demo
//
//  Created by Hollan on 5/31/25.
//

#include <metal_stdlib>
#include "metalBasic.h"
using namespace metal;

struct AxisVertexOut {
    float4 position [[position]];
    float3 worldPosition;
};

constant float axisMajorSpacing = 10.0;
constant float axisMinorSpacing = 1.0;
constant float axisThickness = 0.01;

AxisVertexOut vertex infiniteAxisVertex(const device float3* vertices [[buffer(0)]],
                                    uint vid [[vertex_id]],
                                    constant float4x4& modelMatrix [[buffer(1)]],
                                    constant float4x4& camera [[buffer(2)]],
                                    constant float4x4& proj [[buffer(3)]]
                                    ) {
    AxisVertexOut out;
    float4 worldPos = (modelMatrix * float4(vertices[vid], 1.0));
    out.position = worldPos;
    out.worldPosition = (proj * camera * worldPos).xyz;
    
    return out;
}

float4 fragment infiniteAxisFragment(AxisVertexOut in [[stage_in]]) {
    float2 gridCoord = in.worldPosition.xy;
    
    float2 minor = abs(fract(gridCoord / axisMajorSpacing) - 0.5);
    float2 major = abs(fract(gridCoord / axisMajorSpacing) - 0.5);
    
    float minorLine = step(min(minor.x, minor.y), axisThickness);
    float majorLine = step(min(major.y, major.y), axisThickness * 2.0);
    
    float intensity = max(minorLine * 0.4, majorLine);
    
    return float4(intensity, intensity, intensity, 1.0);
}

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

//
//  triangleShader.metal
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexPayload {
    float4 position [[position]]; //Mesh vertex type
    half3 color;
};

constant float4 positions[] = {
    float4(-0.75, -0.75, 0.0, 1.0),
    float4(0.75, -0.75, 0.0, 1.0),
    float4(0.0, 0.75, 0.0, 1.0)
};

constant half3 colors[] = {
    half3(1.0, 0.0, 0.0), //Red, bottom left corner
    half3(0.0, 1.0, 0.0), //Green, bottom right
    half3(0.0, 0.0, 1.0) //Blue, top
};

/// Creates the layout and outlines the colors of the points.
VertexPayload vertex triangleVertexMain(uint vertexID [[vertex_id]]) {
    VertexPayload payload;
    payload.position = positions[vertexID];
    payload.color = colors[vertexID];
    return payload;
}

/// Separates the colors into distinct values for the GPU.
half4 fragment triangleFragmentMain(VertexPayload frag [[stage_in]]) {
    return half4(frag.color, 1.0);
}

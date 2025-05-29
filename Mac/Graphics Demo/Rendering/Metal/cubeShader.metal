//
//  cubeShader.metal
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

#include <metal_stdlib>
using namespace metal;

struct CubeVertexPayload {
    float4 position [[position]];
    half3 color;
};

constant float4 positions[] = {
    
};

constant half3 colors[] = {
    half3(1.0, 0.0, 0.0)
};

CubeVertexPayload vertex cubeVertexMain(uint vertexID [[vertex_id]]) {
    CubeVertexPayload payload;
    payload.position = positions[vertexID];
    payload.color = colors[vertexID];
    return payload;
}

half4 fragment cubeFragmentMain(CubeVertexPayload frag [[stage_in]]) {
    return half4(frag.color, 1.0);
}

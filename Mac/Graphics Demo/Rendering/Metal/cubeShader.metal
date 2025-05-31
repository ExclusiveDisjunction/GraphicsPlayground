//
//  cubeShader.metal
//  Graphics Demo
//
//  Created by Hollan on 5/23/25.
//

#include <metal_stdlib>
using namespace metal;

struct CubeVertex {
    float3 position;
    float3 color;
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
};

VertexOut vertex cubeVertexMain(
        const device CubeVertex* vertices [[buffer(0)]],
        const device float4x4* modelMatrices [[buffer(1)]],
        constant float4x4& perspective [[buffer(2)]],
        constant float4x4& camera [[buffer(3)]],
        uint vertexID [[vertex_id]],
        uint instanceID [[instance_id]]
) {
    CubeVertex targetVertex = vertices[vertexID];
    float4x4 model = modelMatrices[instanceID];
    float4 output = perspective * camera * model * float4(vertices[vertexID].position, 1.0); //Proper order calculated by the GPU
    
    VertexOut out;
    out.position = output;
    out.color = targetVertex.color;
    return out;
}

float4 fragment cubeFragmentMain(VertexOut frag [[stage_in]]) {
    return float4(frag.color, 1.0);
}

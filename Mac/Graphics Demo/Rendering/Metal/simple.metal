//
//  simple.metal
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

#include <metal_stdlib>
#include "metalBasic.h"
using namespace metal;

VertexOut vertex simple3dVertex(const device VertexIn* vertices [[buffer(0)]],
                                const device float4x4* modelMatrices [[buffer(1)]],
                                constant float4x4& perspective [[buffer(2)]],
                                constant float4x4& camera [[buffer(3)]],
                                uint vertexID [[vertex_id]],
                                uint instanceID [[instance_id]]
                                ) {
    VertexIn targetVertex = vertices[vertexID];
    float4x4 model = modelMatrices[instanceID];
    float4 output = perspective * camera * model * float4(vertices[vertexID].position, 1.0); //Proper order calculated by the GPU
    
    VertexOut out;
    out.position = output;
    out.color = targetVertex.color;
    return out;
}

float4 fragment simple3dFragment(VertexOut frag [[stage_in]]) {
    return float4(frag.color, 1.0);
}

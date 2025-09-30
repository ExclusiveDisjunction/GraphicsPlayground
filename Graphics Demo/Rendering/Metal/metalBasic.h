//
//  metalBasic.h
//  Graphics Demo
//
//  Created by Hollan Sellars on 5/31/25.
//

#ifndef metalBasic_h
#define metalBasic_h

#include <metal_stdlib>

struct VertexIn {
    metal::float3 position;
    metal::float3 color;
};

struct VertexOut {
    metal::float4 position [[position]];
    metal::float3 color;
};


#endif /* metalBasic_h */

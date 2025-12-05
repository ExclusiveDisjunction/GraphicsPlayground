//
//  common.h
//  FlowField
//
//  Created by Hollan Sellars on 12/2/25.
//

#ifndef common_h
#define common_h

#include <simd/simd.h>

typedef struct {
    vector_float3 min;
    vector_float3 max;
} ColorSchema;

typedef struct {
    vector_float2 tail;
    vector_float2 angMag; // The first value is the angle, while the second is the magnitude.
} FlowVector;

typedef struct  {
    vector_float4 pos [[position]];
    float mag;
} OutputFlowVector;

typedef struct {
    uint x;
    uint y;
} SizeUint;

typedef struct {
    vector_float2 step;
    vector_uint2 size;
    vector_float2 corner;
} VectorsSetupCx;

#endif /* common_h */

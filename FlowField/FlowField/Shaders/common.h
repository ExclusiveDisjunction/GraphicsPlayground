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
    float angle;
    float mag;
} ParametricVector;

typedef struct {
    vector_float2 tail;
    vector_float2 tip;
} TailTipVector;

typedef struct {
    vector_float2 bottomLeft;
    vector_float2 bottomRight;
    vector_float2 topLeft;
    vector_float2 topRight;
    vector_float2 t_left;
    vector_float2 t_right;
    vector_float2 t_top;
    float mag;
} RenderableVector;

typedef struct  {
    vector_float4 pos [[position]];
    float mag;
} OutputVector;

typedef struct {
    vector_float2 step;
    vector_float2 corner;
    unsigned sizex;
    unsigned sizey;
} VectorSetupContext;

typedef struct {
    vector_float2 step;
    unsigned sizex;
    unsigned sizey;
    float time;
    float deltaTime;
} VectorAnimateContext;

typedef struct {
    float zoom;
    simd_float4x4 transform;
} VectorVertexContext;

#endif /* common_h */

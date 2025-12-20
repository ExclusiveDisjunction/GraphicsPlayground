//
//  common.h
//  GraphViewer
//
//  Created by Hollan Sellars on 12/19/25.
//

#ifndef common_h
#define common_h

#include <simd/simd.h>

typedef struct {
    float thickness;
    float spacing;
    float zoom;
    vector_float2 offset;
    vector_float4 background;
    vector_float4 line;
} GridProperties;

#endif /* common_h */

//
//  GridRenderer.metal
//  GraphViewer
//
//  Created by Hollan Sellars on 12/19/25.
//

#include <metal_stdlib>
#include "../common.h"
using namespace metal;

kernel void renderGrid(
   texture2d<float, access::write> out [[texture(0)]],
   const device GridProperties& properties [[buffer(0)]],
   uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x > out.get_width() || gid.y > out.get_height()) {
        return;
    }
    
    float spacing = properties.spacing * properties.zoom;
    
    float2 pos = float2(gid);
    float dx = abs(fract(pos.x / spacing) - 0.5) * spacing;
    float dy = abs(fract(pos.y / spacing) - 0.5) * spacing;
    
    float d = min(dx, dy);
    
    float alpha = smoothstep(properties.thickness, properties.thickness - 1.0, d);
    
    float4 color =  mix(properties.background, properties.line, alpha); // float4(alpha, alpha, alpha, 1.0); // mix(alpha, properties.background, properties.line);
    out.write(color, gid);
}

struct OutputInformation {
    float4 pos [[position]];
    float2 uv;
};

vertex OutputInformation gridVertex(
     uint vid [[vertex_id]]
) {
    float4 pos[4] = {
        {-1, -1, 0, 1}, {1, -1, 0, 1},
        {-1,  1, 0, 1}, {1,  1, 0, 1}
    };
    
    float2 tex[4] = {
        {0, 1}, {1, 1},
        {0, 0}, {1, 0}
    };
    
    OutputInformation result;
    result.uv = tex[vid];
    result.pos = pos[vid];
    return result;
}

fragment float4 gridFragment(
     OutputInformation input [[stage_in]],
     texture2d<float> tex [[texture(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::nearest);
    return tex.sample(s, input.uv);
}

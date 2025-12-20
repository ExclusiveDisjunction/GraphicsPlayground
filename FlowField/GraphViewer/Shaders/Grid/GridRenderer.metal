//
//  GridRenderer.metal
//  GraphViewer
//
//  Created by Hollan Sellars on 12/19/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void renderGrid(
   texture2d<float, access::write> out [[texture(0)]],
   const device float& spacing [[buffer(0)]],
   const device float& thickness [[buffer(1)]],
   uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x > out.get_width() || gid.y > out.get_height()) {
        return;
    }
    
    float2 pos = float2(gid);
    float dx = abs(fract(pos.x / spacing) - 0.5) * spacing;
    float dy = abs(fract(pos.y / spacing) - 0.5) * spacing;
    
    float d = min(dx, dy);
    
    float alpha = smoothstep(thickness, thickness - 1.0, d);
    
    float4 color = float4(1.0, 1.0, 1.0, alpha);
    out.write(color, gid);
}

vertex float4 gridVertex(
     uint vid [[vertex_id]],
     float2 uv [[user(locn0)]]
) {
    float2 pos[4] = {
        {-1, -1}, {1, -1},
        {-1,  1}, {1,  1}
    };
    
    float2 tex[4] = {
        {0, 1}, {1, 1},
        {0, 0}, {1, 0}
    };
    
    uv = tex[vid];
    return float4(pos[vid], 0, 1);
}

fragment float4 gridFragment(
     float2 uv [[stage_in]],
     texture2d<float> tex [[texture(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::nearest);
    return tex.sample(s, uv);
}

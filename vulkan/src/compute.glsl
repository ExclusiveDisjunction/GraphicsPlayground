#version 460

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0) buffer DataA {
    float data[];
} buffA;
layout(set = 0, binding = 1) buffer DataB {
    float data[];
} buffB;
layout(set = 0, binding = 2) buffer DataC {
    float data[];
} result;

void main() {
    uint idx = gl_GlobalInvocationID.x;
    result.data[idx] = buffA.data[idx] + buffB.data[idx];
}
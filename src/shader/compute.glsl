#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img;
uniform ivec2 iResolution;

// uniform float time;

void main() {

    ivec2 iCoords = ivec2(gl_GlobalInvocationID.xy);

    vec2 uv = vec2(iCoords) / iResolution;

    vec4 pixel = vec4(uv, 0.0, 1.0);

    imageStore(img, iCoords, pixel);

}
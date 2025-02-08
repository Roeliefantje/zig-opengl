#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img;
uniform ivec2 iResolution;

uniform int frame;

void main() {

    ivec2 iCoords = ivec2(gl_GlobalInvocationID.xy);

    vec2 uv = vec2(iCoords) / iResolution;

    float zColor = mod(frame, 256) / 256.0;

    vec4 pixel = vec4(uv, zColor, 1.0);

    imageStore(img, iCoords, pixel);

}
#version 430
layout(local_size_x = 128, local_size_y = 1) in;
layout(r32f, binding = 0) uniform image2D img;
uniform ivec2 iResolution;

uniform sampler2D mainTex;

uniform vec2 thresholds;

void main() {

    ivec2 iCoords = ivec2(gl_GlobalInvocationID.xy);

    vec2 top_left = vec2(iCoords.x - 1, iCoords.y - 1) / iResolution;
    vec2 middle_left = vec2(iCoords.x - 1, iCoords.y) / iResolution;
    vec2 bottom_left = vec2(iCoords.x - 1, iCoords.y + 1) / iResolution;

    vec2 top_right = vec2(iCoords.x + 1, iCoords.y - 1) / iResolution;
    vec2 middle_right = vec2(iCoords.x + 1, iCoords.y) / iResolution;
    vec2 bottom_right = vec2(iCoords.x + 1, iCoords.y + 1) / iResolution;


    vec4 leftColor = -1 * texture(mainTex, top_left) + -2 * texture(mainTex, middle_left) + -1 * texture(mainTex, top_left);
    vec4 rightColor = 1 * texture(mainTex, top_right) + 2 * texture(mainTex, middle_right) + 1 * texture(mainTex, bottom_right);

    float val = abs(dot((leftColor + rightColor).rgb, vec3(0.3, 0.59, 0.11)));

    if (val > thresholds.x) {
        imageStore(img, iCoords, vec4(0,0,0,1));
    } else {
        imageStore(img, iCoords, vec4(1, 1, 1,1));
    }

    // imageStore(img, iCoords, vec4(val));
    // vec2 uv = vec2(iCoords) / iResolution;


    // float luminance = dot(texture(mainTex, uv).rgb, vec3(0.3, 0.59, 0.11));
    // if (luminance < thresholds.x || luminance > thresholds.y) {
    //     imageStore(img, iCoords, vec4(0, 0, 0, 1));
    // } else {
    //     // vec4 color = vec4(luminance);

    //     // imageStore(img, iCoords, color);
    //     imageStore(img, iCoords, vec4(1, 1, 1, 1));
    // }

    
}
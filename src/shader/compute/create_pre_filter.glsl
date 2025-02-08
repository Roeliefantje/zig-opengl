#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(r32f, binding = 0) uniform image2D helpImg;
layout(r32f, binding = 1) uniform image2D maskImg;
uniform ivec2 iResolution;

uniform sampler2D mainTex;


// This filter will go over the mask and assign values based on which band it is apart of.
// So the red channel will be 
void main() {

    uint y = gl_GlobalInvocationID.y;
    float start_value = 0.0;
    float increment_value = 1.0 / iResolution.x;
    
    for (uint x = 0; x < iResolution.x; x++) {
        float mask = imageLoad(maskImg, ivec2(x, y)).r;
        imageStore(helpImg, ivec2(x, y), vec4(start_value));
        if (mask <= 0.1) {
            start_value += increment_value;
        }
    }
}
#version 430
layout(local_size_x = 1024, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img;
layout(r32f, binding = 1) uniform image2D helpImg;
uniform ivec2 iResolution;

uniform sampler2D mainTex;

void main() {

    ivec2 iCoords = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(iCoords) / iResolution;

    int numPairs = 511;
    int numStages = int(log2(numPairs * 2)) + 1;

    //Initialize image
    vec4 initial = vec4(texture(mainTex, uv).rgb, 1);
    // vec4 initial = vec4(imageLoad(helpImg, iCoords));
    imageStore(img, iCoords, initial);
    barrier();


    // // // // // Perform bitonic sort
    for (int stage = 0; stage < numStages; stage++) {
        for (int pass = 0; pass < stage; pass++){
            int groupWidth = 1 << (stage - pass);
            int groupHeight = 2 * groupWidth - 1;

            uint i = iCoords.x;
            uint h = i & (groupWidth - 1);
            uint indexLow = h + (groupHeight + 1) * (i / groupWidth);
            uint indexHigh = indexLow + (pass == 0 ? groupHeight - 2 * h : (groupHeight + 1) / 2);

            vec4 valueLow = imageLoad(img, ivec2(indexLow, iCoords.y));
            vec4 valueHigh = imageLoad(img, ivec2(indexHigh, iCoords.y));

            float helpValueLow = imageLoad(helpImg, ivec2(indexLow, iCoords.y)).r;
            float helpValueHigh = imageLoad(helpImg, ivec2(indexHigh, iCoords.y)).r;

            float magLow = valueLow.r + helpValueLow * 2048;
            float magHigh = valueHigh.r + helpValueHigh * 2048;

            if (magLow > magHigh) {
                imageStore(img, ivec2(indexLow, iCoords.y), valueHigh);
                imageStore(helpImg, ivec2(indexLow, iCoords.y), vec4(helpValueHigh));


                imageStore(img, ivec2(indexHigh, iCoords.y), valueLow);
                imageStore(helpImg, ivec2(indexHigh, iCoords.y), vec4(helpValueLow));
            }

            groupMemoryBarrier();
            barrier();
        }
    }

}
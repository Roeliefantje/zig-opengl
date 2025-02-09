#version 430
layout(local_size_x = 1024, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img;
layout(r32f, binding = 1) uniform image2D helpImg;
uniform ivec2 iResolution;

uniform sampler2D mainTex;

uint nextPowerOf2(uint x) {
    return 1u << uint(ceil(log2(float(x))));
}

void main() {

    ivec2 iCoords = ivec2(gl_GlobalInvocationID.xy);
    // vec2 uv = vec2(iCoords) / iResolution;

    uint n = nextPowerOf2(iResolution.x);

    // uint amount_of_pixels = uint(ceil(n / 1024)); //Ceil so its always at least 1 :)

    int numPairs = int(n / 2);
    int numStages = int(log2(numPairs * 2));

    //Initialize image
    for (uint i = uint(iCoords.x); i < uint(iResolution.x); i += 1024){
        ivec2 pixelCoords = ivec2(i, iCoords.y);
        vec2 uv = vec2(pixelCoords) / iResolution;
        vec4 initial = vec4(texture(mainTex, uv).rgb, 1);
        // vec4 initial = vec4(imageLoad(helpImg, iCoords));
        imageStore(img, pixelCoords, initial);
    }
    groupMemoryBarrier();
    barrier();

    
    // // // // // Perform bitonic sort
    
        
    for (int stage = 0; stage < numStages; stage++) {
        for (int pass = 0; pass < stage; pass++){
            for (uint i = uint(iCoords.x); i < uint(iResolution.x); i += 1024){
                int groupWidth = 1 << (stage - pass);
                int groupHeight = 2 * groupWidth - 1;

                // uint i = iCoords.x;
                uint h = i & (groupWidth - 1);
                uint indexLow = h + (groupHeight + 1) * (i / groupWidth);
                uint indexHigh = indexLow + (pass == 0 ? groupHeight - 2 * h : (groupHeight + 1) / 2);

                if (indexHigh >= iResolution.x) {
                    continue;
                }

                vec4 valueLow = imageLoad(img, ivec2(indexLow, iCoords.y));
                vec4 valueHigh = imageLoad(img, ivec2(indexHigh, iCoords.y));

                float helpValueLow = imageLoad(helpImg, ivec2(indexLow, iCoords.y)).r;
                float helpValueHigh = imageLoad(helpImg, ivec2(indexHigh, iCoords.y)).r;

                // float magLow = length(valueLow) + helpValueLow * 2048;
                // float magHigh = length(valueHigh) + helpValueHigh * 2048;

                vec3 grayScaleMultipliers = vec3(0.3, 0.59, 0.11);

                float magLow = dot(valueLow.rgb, grayScaleMultipliers)  + helpValueLow * iResolution.x;
                float magHigh = dot(valueHigh.rgb, grayScaleMultipliers) + helpValueHigh * iResolution.x;

                if (magLow > magHigh) {
                    imageStore(img, ivec2(indexLow, iCoords.y), valueHigh);
                    imageStore(helpImg, ivec2(indexLow, iCoords.y), vec4(helpValueHigh));


                    imageStore(img, ivec2(indexHigh, iCoords.y), valueLow);
                    imageStore(helpImg, ivec2(indexHigh, iCoords.y), vec4(helpValueLow));
                }

                
            }

            groupMemoryBarrier();
            barrier();
        }
    }
    

}
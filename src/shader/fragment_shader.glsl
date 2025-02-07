#version 330 core
out vec4 FragColor;

in vec2 uv;

uniform sampler2D mainTex;

void main()
{
    // FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    FragColor = texture(mainTex, uv);
    // FragColor = vec4(uv.x, uv.y, 0.0f, 0.0f);
}

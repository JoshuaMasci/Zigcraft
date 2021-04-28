#version 330 core
out vec4 FragColor;

in vec2 tex_uv;

uniform sampler2D block_texture;

void main()
{
    FragColor = texture(block_texture, tex_uv);
    //FragColor = vec4(tex_uv, 0.0, 1.0);
} 
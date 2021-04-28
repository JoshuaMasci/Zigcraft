#version 330 core
out vec4 FragColor;

in vec3 out_color;

void main()
{
    FragColor = texture(ourTexture, out_color.xy);
} 
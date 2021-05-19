#version 330 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 uv;

uniform mat4 view_projection_matrix;
uniform mat4 model_matrix;

void main()
{
    gl_Position = view_projection_matrix * model_matrix * vec4(pos, 1.0);
}
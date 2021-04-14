#version 330 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 color;

uniform mat4 view_projection_matrix;
uniform mat4 model_matrix;

out vec3 out_color;

void main()
{
    gl_Position = view_projection_matrix * model_matrix * vec4(pos, 1.0);
    out_color = color;
}
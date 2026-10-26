#version 330 core

layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec2 a_uv;

uniform mat4 u_proj;
uniform mat4 u_view;
uniform mat4 u_model;
uniform vec2 u_snap;

out vec3 v_world;
out vec3 v_normal;
out vec2 v_uv;
out float v_depth;

void main()
{
    vec4 world = u_model * vec4(a_pos, 1.0);
    vec4 view = u_view * world;
    vec4 clip = u_proj * view;

    // Snap to the low-res pixel grid for the wobbly, unfiltered look of
    // fixed-point era hardware.
    if (clip.w > 0.0)
        clip.xy = floor(clip.xy / clip.w * u_snap + 0.5) / u_snap * clip.w;

    v_world = world.xyz;
    v_normal = mat3(u_model) * a_normal;
    v_uv = a_uv;
    v_depth = -view.z;
    gl_Position = clip;
}

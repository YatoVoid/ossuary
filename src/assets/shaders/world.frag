#version 330 core

#define MAX_LIGHTS 8

in vec3 v_world;
in vec3 v_normal;
in vec2 v_uv;
in float v_depth;

uniform sampler2D u_tex;
uniform vec3 u_tint;
uniform vec3 u_emissive;

uniform int u_light_count;
uniform vec3 u_light_pos[MAX_LIGHTS];
uniform vec3 u_light_color[MAX_LIGHTS];
uniform float u_light_radius[MAX_LIGHTS];

uniform vec3 u_ambient;
uniform vec3 u_fog_color;
uniform float u_fog_density;

out vec4 o_color;

void main()
{
    vec3 albedo = texture(u_tex, v_uv).rgb * u_tint;
    vec3 n = normalize(v_normal);
    vec3 light = u_ambient;

    for (int i = 0; i < u_light_count; i++) {
        vec3 to_light = u_light_pos[i] - v_world;
        float d = length(to_light);
        float falloff = clamp(1.0 - d / u_light_radius[i], 0.0, 1.0);
        falloff *= falloff;
        float facing = max(dot(n, to_light / max(d, 0.001)), 0.0);
        light += u_light_color[i] * falloff * (facing * 0.85 + 0.15);
    }

    vec3 color = albedo * light + u_emissive;
    float fog = 1.0 - exp(-pow(v_depth * u_fog_density, 2.0));
    o_color = vec4(mix(color, u_fog_color, clamp(fog, 0.0, 1.0)), 1.0);
}

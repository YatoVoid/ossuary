#version 330 core

in vec2 v_uv;

uniform sampler2D u_scene;
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_dread;
uniform float u_fade;
uniform vec3 u_fade_color;

out vec4 o_color;

const float BAYER[16] = float[16](
     0.0,  8.0,  2.0, 10.0,
    12.0,  4.0, 14.0,  6.0,
     3.0, 11.0,  1.0,  9.0,
    15.0,  7.0, 13.0,  5.0);

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    float pulse = 0.5 + 0.5 * sin(u_time * (2.0 + u_dread * 5.0));

    vec2 uv = v_uv;
    uv.x += sin(uv.y * 38.0 + u_time * 3.0) * 0.0016 * u_dread * u_dread;
    vec3 c = texture(u_scene, uv).rgb;

    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(c, lum * vec3(1.15, 0.82, 0.78), u_dread * 0.55);

    vec2 q = v_uv - 0.5;
    float vignette = clamp(1.0 - dot(q, q) * (1.2 + u_dread * 1.8 * pulse), 0.0, 1.0);
    c *= vignette;
    c += vec3(0.09, 0.0, 0.0) * u_dread * pulse * (1.0 - vignette);

    vec2 px = floor(v_uv * u_resolution);
    c += (hash(px + floor(u_time * 24.0)) - 0.5) * 0.03;

    int bx = int(mod(px.x, 4.0));
    int by = int(mod(px.y, 4.0));
    float threshold = BAYER[by * 4 + bx] / 16.0;
    c = floor(c * 31.0 + threshold) / 31.0;

    o_color = vec4(mix(c, u_fade_color, u_fade), 1.0);
}

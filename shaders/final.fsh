#version 460 compatibility

in vec4 texcoord;
uniform sampler2D gcolor;
uniform sampler2D colortex14;
uniform sampler2D colortex15;
out vec4 fragcolor;

// Constants
const float fact = .5 / log2(39.);

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;
    vec3 dither = texture(colortex15, gl_FragCoord.xy / 1024.).rgb;
    color += (dither - .5) * fact;
    color = clamp(color, .0, .98);
    ivec3 rgb = ivec3(round(color * 255.));
    int index = (rgb.r << 16) | (rgb.g << 8) | rgb.b;
    fragcolor = texture(colortex14, vec2(index & 4095, index >> 12) / 4095.);
}
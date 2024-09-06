#version 460 compatibility

#define GAMMA 1.0 // Gamma correction [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2]
#define DITHER_FACTOR 0.5 // Amount of dithering to apply [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DITHER_METHOD 0 // Dithering method [0 1]
#define DITHER_CMAP 0 // Dither color palette [0 1 2 3 4 5 6]
#define DITHER_BAYER4X4 0
#define DITHER_BLUENOISE1024X1024 1
#define DITHER_COLOR // Dither color

#if DITHER_METHOD == DITHER_BAYER4X4
const mat4 bayerIndex = mat4(
vec4(0.0/16.0, 12.0/16.0, 3.0/16.0, 15.0/16.0),
vec4(8.0/16.0, 4.0/16.0, 11.0/16.0, 7.0/16.0),
vec4(2.0/16.0, 14.0/16.0, 1.0/16.0, 13.0/16.0),
vec4(10.0/16.0, 6.0/16.0, 9.0/16.0, 5.0/16.0)
);
#endif

#ifndef DITHER_COLOR
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);
#endif

in vec2 texcoord;
uniform sampler2D colortex0;
#if DITHER_METHOD == DITHER_BLUENOISE1024X1024
uniform sampler2D colortex8;
#endif
#ifdef DITHER_COLOR
uniform sampler2D colortex9;
#endif
out vec4 fragcolor;

void main() {
    vec4 color = pow(texture(colortex0, texcoord), vec4(GAMMA));
    #if DITHER_METHOD == DITHER_BAYER4X4
    vec4 dither = vec4(bayerIndex[int(gl_FragCoord.x) & 0x3][int(gl_FragCoord.y) & 0x3]) - .5;
    #elif DITHER_METHOD == DITHER_BLUENOISE1024X1024
    vec4 dither = texture(colortex8, gl_FragCoord.xy / 1024.) - .5;
    #endif
    color = clamp(color + dither * DITHER_FACTOR, .0, .97);
    #ifdef DITHER_COLOR
    ivec4 rgb = ivec4(round(color * 255.));
    int index = (rgb.r << 16) | (rgb.g << 8) | rgb.b;
    fragcolor = texture(colortex9, vec2(index & 4095, index >> 12) / 4095.);
    #else
    fragcolor = vec4(vec3(dot(color.rgb, grayscaleFactor) > .5), 1.);
    #endif
}
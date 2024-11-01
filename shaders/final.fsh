#version 460 compatibility

// Configuration
#define GAMMA 1.0 // Gamma correction [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2]
#define DITHER_FACTOR 0.5 // Amount of dithering to apply [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DITHER_METHOD 21 // Dithering method [0 1 2 3 10 11 12 13 14 15 16 20 21]
#define DITHER_COLORMAP 2 // Dither color palette [0 1 2 3 4 5 6 7]
#define DITHER_COLOR // Dither color

// Dithering methods
// Bayer
#define DITHER_BAYER2 0
#define DITHER_BAYER4 1
#define DITHER_BAYER8 2
#define DITHER_BAYER16 3

// Blue noise
#define DITHER_BLUENOISE16 10
#define DITHER_BLUENOISE32 11
#define DITHER_BLUENOISE64 12
#define DITHER_BLUENOISE128 13
#define DITHER_BLUENOISE256 14
#define DITHER_BLUENOISE512 15
#define DITHER_BLUENOISE1024 16

// Misc
#define DITHER_IGN 20
#define DITHER_R2 21

#ifdef DITHER_COLOR
uniform sampler2D colortex9;
#else
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);
#endif

#if DITHER_METHOD == DITHER_IGN
const float a = 52.9829189;
const vec2 magic = vec2(0.06711056, 0.00583715);
#elif DITHER_METHOD == DITHER_R2
const float phi_2 = 1.32471796;
const vec2 magic = vec2(1.0 / phi_2, 1.0 / (phi_2 * phi_2));
#else
uniform sampler2D colortex8;
uniform int size;
#endif

in vec2 texcoord;
uniform sampler2D colortex0;
out vec4 fragcolor;

void main() {
    vec4 color = pow(texture(colortex0, texcoord), vec4(GAMMA));
    #if DITHER_METHOD == DITHER_IGN
    vec4 dither = vec4(fract(a * fract(dot(vec2(gl_FragCoord.xy), magic)))) - .5;
    #elif DITHER_METHOD == DITHER_R2
    vec4 dither = vec4(fract(dot(vec2(gl_FragCoord.xy), magic))) - .5;
    #else
    vec4 dither = texelFetch(colortex8, ivec2(gl_FragCoord.xy) % size, 0) - .5;
    #endif
    color = clamp(color + dither * DITHER_FACTOR, .0, 1.);
    #ifdef DITHER_COLOR
    ivec4 rgb = ivec4(round(color * 255.));
    int index = (rgb.r << 16) | (rgb.g << 8) | rgb.b;
    fragcolor = texelFetch(colortex9, ivec2(index & 4095, index >> 12), 0);
    #else
    fragcolor = vec4(vec3(dot(color.rgb, grayscaleFactor) > .5), 1.);
    #endif
}
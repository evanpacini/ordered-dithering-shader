#version 400 compatibility

// Configuration
#define GAMMA 1.0 // Gamma correction [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2]
#define DITHER_FACTOR 0.5 // Amount of dithering to apply [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DITHER_METHOD 21 // Dithering method [0 1 2 3 10 11 12 13 14 15 16 20 21]
#define DITHER_COLORMAP 1 // Dither color palette [0 1 2 3 4 5 6 7]
#define DITHER_COLOR // Dither color
#define LOD 0 // Level of detail [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
const float lodf = 1.0 / (1 << LOD);

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
#endif

uniform sampler2D colortex0;
const bool colortex0MipmapEnabled = true;

void main() {
    vec4 color = pow(texelFetch(colortex0, ivec2(gl_FragCoord.xy * lodf), LOD), vec4(GAMMA));
    #if DITHER_METHOD == DITHER_IGN
    float dither = fract(a * fract(dot(floor(gl_FragCoord.xy * lodf), magic))) - .5;
    #elif DITHER_METHOD == DITHER_R2
    float dither = fract(dot(floor(gl_FragCoord.xy * lodf), magic)) - .5;
    #else
    float dither = texelFetch(colortex8, ivec2(gl_FragCoord.xy * lodf) % textureSize(colortex8, 0).x, 0).r - .5;
    #endif
    color = clamp(color + dither * DITHER_FACTOR, 0, 1);
    #ifdef DITHER_COLOR
    uint index = packUnorm4x8(color) & 0xFFFFFFu;
    gl_FragColor = texelFetch(colortex9, ivec2(index & 4095u, index >> 12), 0);
    #else
    gl_FragColor = vec4(vec3(dot(color.rgb, grayscaleFactor) > .5), 1.);
    #endif
}
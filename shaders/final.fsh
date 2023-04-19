#version 450 compatibility

// Constants
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);
const mat4 bayerIndex = mat4(
0.0/16.0, 12.0/16.0, 3.0/16.0, 15.0/16.0,
8.0/16.0, 4.0/16.0, 11.0/16.0, 7.0/16.0,
2.0/16.0, 14.0/16.0, 1.0/16.0, 13.0/16.0,
10.0/16.0, 6.0/16.0, 9.0/16.0, 5.0/16.0
);

const vec3 palette[16] = vec3[16](
vec3(0.82,0.694,0.529),
vec3(0.78,0.482,0.345),
vec3(0.682,0.365,0.251),
vec3(0.475,0.267,0.29),
vec3(0.294,0.239,0.267),
vec3(0.729,0.569,0.345),
vec3(0.573,0.455,0.255),
vec3(0.302,0.271,0.224),
vec3(0.467,0.455,0.231),
vec3(0.702,0.647,0.333),
vec3(0.824,0.788,0.647),
vec3(0.549,0.671,0.631),
vec3(0.294,0.447,0.431),
vec3(0.341,0.282,0.322),
vec3(0.518,0.471,0.459),
vec3(0.671,0.608,0.557)
);

// Inputs
in vec4 texcoord;
uniform sampler2D gcolor;

// Outputs
out vec4 fragcolor;

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;
    float bayerValue = bayerIndex[int(gl_FragCoord.x) & 0x3][int(gl_FragCoord.y) & 0x3];

    // Convert color to index in the color palette
    int index = 0;
    float closestDist = dot(color - palette[0], color - palette[0]);
    for (int i = 1; i < 16; i++) {
        float dist = dot(color - palette[i], color - palette[i]);
        if (dist < closestDist) {
            index = i;
            closestDist = dist;
        }
    }

    // Quantize color to closest color in the palette
    vec3 quantizedColor = palette[index];

    // Threshold using bayerValue
    float luminance = dot(grayscaleFactor, quantizedColor);
    quantizedColor = step(bayerValue, luminance) * quantizedColor;

    fragcolor = vec4(quantizedColor, 1.0f);
}
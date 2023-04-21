#version 450 compatibility

// Constants
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);
const vec3 referenceWhite = vec3(95.047, 100.000, 108.883);

const mat4 bayerIndex = mat4(
vec4(0.0/16.0, 12.0/16.0, 3.0/16.0, 15.0/16.0),
vec4(8.0/16.0, 4.0/16.0, 11.0/16.0, 7.0/16.0),
vec4(2.0/16.0, 14.0/16.0, 1.0/16.0, 13.0/16.0),
vec4(10.0/16.0, 6.0/16.0, 9.0/16.0, 5.0/16.0)
);

const mat3 XYZ = mat3(
vec3(0.4124, 0.3576, 0.1805),
vec3(0.2126, 0.7152, 0.0722),
vec3(0.0193, 0.1192, 0.9505)
);

const vec3 palette[] = vec3[](
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

const float numberOfColors = float(palette.length());

// Inputs
in vec4 texcoord;
uniform sampler2D gcolor;

// Outputs
out vec4 fragcolor;

vec3 sRGBToLinear(vec3 srgb) {
    bvec3 cutoff = lessThan(srgb, 0.04045.xxx);
    vec3 higher = pow((srgb + 0.055) / 1.055, 2.4.xxx);
    vec3 lower = srgb / 12.92;
    return mix(higher, lower, cutoff);
}

vec3 linearTosRGB(vec3 linear) {
    bvec3 cutoff = lessThan(linear, 0.0031308.xxx);
    vec3 higher = 1.055 * pow(linear, vec3(1.0 / 2.4)) - 0.055;
    vec3 lower = linear * 12.92;
    return mix(higher, lower, cutoff);
}

vec3 sRGBToXYZ(vec3 srgb) {
    return sRGBToLinear(srgb) * 100.0 * XYZ;
}

vec3 XYZTosRGB(vec3 xyz) {
    return linearTosRGB(xyz / 100.0 * inverse(XYZ));
}

vec3 XYZToLab(vec3 xyz) {
    vec3 n = xyz / referenceWhite;
    bvec3 cutoff = lessThan(n, 0.008856.xxx);
    vec3 higher = pow(n, vec3(1.0 / 3.0));
    vec3 lower = 7.787 * n + vec3(16.0 / 116.0);
    n = mix(higher, lower, cutoff);
    return vec3(116.0 * n.y - 16.0, 500.0 * (n.x - n.y), 200.0 * (n.y - n.z));
}

vec3 LabToXYZ(vec3 lab) {
    vec3 n;
    n.y = (lab.x + 16.0) / 116.0;
    n.x = lab.y / 500.0 + n.y;
    n.z = n.y - lab.z / 200.0;
    bvec3 cutoff = lessThan(pow(n, 3.0.xxx), 0.008856.xxx);
    vec3 higher = pow(n, 3.0.xxx);
    vec3 lower = (n - vec3(16.0 / 116.0)) / 7.787;
    n = mix(higher, lower, cutoff);
    return n * referenceWhite;
}

vec3 sRGBToLab(vec3 srgb) {
    return XYZToLab(sRGBToXYZ(srgb));
}

vec3 LabTosRGB(vec3 lab) {
    return XYZTosRGB(LabToXYZ(lab));
}

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;
    float bayerValue = bayerIndex[int(gl_FragCoord.x) & 0x3][int(gl_FragCoord.y) & 0x3];
    color += bayerValue / numberOfColors;
    color = floor(color * numberOfColors) / numberOfColors;

    color = sRGBToLab(color);

    // Convert color to index in the color palette
    int index = 0;
    float closestDist = distance(color, sRGBToLab(palette[0]));
    for (int i = 1; i < palette.length(); i++) {
        float dist = distance(color, sRGBToLab(palette[i]));
        if (dist < closestDist) {
            index = i;
            closestDist = dist;
        }
    }

    // Quantize color to closest color in the palette
    color = palette[index];

    fragcolor = vec4(color, 1.0f);
}
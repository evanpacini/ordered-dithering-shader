#version 460 compatibility

// Constants
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);
const vec3 referenceWhite = vec3(95.047, 100.000, 108.883);

const mat3 XYZ = mat3(
    vec3(0.4124, 0.3576, 0.1805),
    vec3(0.2126, 0.7152, 0.0722),
    vec3(0.0193, 0.1192, 0.9505)
);

const vec3 palette[] = vec3[](
    vec3(0.820, 0.694, 0.529),
    vec3(0.780, 0.482, 0.345),
    vec3(0.682, 0.365, 0.251),
    vec3(0.475, 0.267, 0.29),
    vec3(0.294, 0.239, 0.267),
    vec3(0.729, 0.569, 0.345),
    vec3(0.573, 0.455, 0.255),
    vec3(0.302, 0.271, 0.224),
    vec3(0.467, 0.455, 0.231),
    vec3(0.702, 0.647, 0.333),
    vec3(0.824, 0.788, 0.647),
    vec3(0.549, 0.671, 0.631),
    vec3(0.294, 0.447, 0.431),
    vec3(0.341, 0.282, 0.322),
    vec3(0.518, 0.471, 0.459),
    vec3(0.671, 0.608, 0.557)
);
const float numberOfColors = float(palette.length());

// Inputs
in vec4 texcoord;
uniform sampler2D gcolor;
uniform sampler2D colortex15;

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

vec3 linearRGBToXYZ(vec3 rgb) {
    return rgb * 100.0 * XYZ;
}

vec3 XYZToLinearRGB(vec3 xyz) {
    return xyz / 100.0 * inverse(XYZ);
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

vec3 linearRGBToLab(vec3 rgb) {
    return XYZToLab(linearRGBToXYZ(rgb));
}

vec3 LabTolinearRGB(vec3 lab) {
    return XYZToLinearRGB(LabToXYZ(lab));
}

vec3 sRGBToLab(vec3 srgb) {
    return XYZToLab(sRGBToXYZ(srgb));
}

vec3 LabTosRGB(vec3 lab) {
    return XYZTosRGB(LabToXYZ(lab));
}

float CIEDE2000(vec3 lab1, vec3 lab2) {
    float C_7 = pow((length(lab1.yz) + length(lab2.yz)) / 2.0, 7.0);
    float G = 0.5 * (1.0 - sqrt(C_7 / (C_7 + 6103515625.0)));

    float a1p = (1.0 + G) * lab1.y;
    float a2p = (1.0 + G) * lab2.y;

    float C1p = length(vec2(a1p, lab1.z));
    float C2p = length(vec2(a2p, lab2.z));

    float h1p = atan(lab1.z, a1p);
    float h2p = atan(lab2.z, a2p);

    float Hp;
    if (abs(h1p - h2p) <= 180.0) {
        Hp = (h1p + h2p) / 2.0;
    } else {
        if (h1p + h2p < 360.0) {
            Hp = (h1p + h2p + 360.0) / 2.0;
        } else {
            Hp = (h1p + h2p - 360.0) / 2.0;
        }
    }

    float Lp = (lab1.x + lab2.x) / 2.0;
    float Cp = (C1p + C2p) / 2.0;

    float T = 1.0 - 0.17 * cos(Hp - 30.0) + 0.24 * cos(2.0 * Hp) + 0.32 * cos(3.0 * Hp + 6.0) - 0.20 * cos(4.0 * Hp - 63.0);
    float deltahp = h2p - h1p;
    if (abs(deltahp) > 180.0) {
        if (deltahp > 0.0) {
            deltahp -= 360.0;
        } else {
            deltahp += 360.0;
        }
    }
    float dHp = 2.0 * sqrt(C1p * C2p) * sin(deltahp / 2.0);

    float LpMinus50Squared = (Lp - 50.0) * (Lp - 50.0);
    float Sl = 1.0 + 0.015 * LpMinus50Squared / sqrt(20.0 + LpMinus50Squared);
    float Sc = 1.0 + 0.045 * Cp;
    float Sh = 1.0 + 0.015 * Cp * T;

    float Rc = 2.0 * sqrt(pow(Cp, 7.0) / (pow(Cp, 7.0) + pow(25.0, 7.0)));

    float Rt = -Rc * sin(2.0 * 30.0 * exp(-((Hp - 275.0) / 25.0) * ((Hp - 275.0) / 25.0)));

    return sqrt(
        pow((lab2.x - lab1.x) / Sl, 2.0) +
        pow((C2p - C1p) / Sc, 2.0) +
        pow(dHp / Sh, 2.0) +
        Rt * (C2p - C1p) / Sc * dHp / Sh
    );
}

void main() {
    // Get color from texture
    vec3 color = texture2D(gcolor, texcoord.st).rgb;

    // Convert color to linear RGB
    color = sRGBToLinear(color);

    // Dither color
    float dither = texture2D(colortex15, gl_FragCoord.xy / 1024).r;
    color += (dither - 0.5) / log2(numberOfColors);

    // Convert color to Lab
    color = linearRGBToLab(color);

    // Get index of closest color in palette
    int index = 0;
    float closestDist = CIEDE2000(color, sRGBToLab(palette[0]));
    for (int i = 1; i < palette.length(); i++) {
        float dist = CIEDE2000(color, sRGBToLab(palette[i]));
        if (dist < closestDist) {
            index = i;
            closestDist = dist;
        }
    }

    // Quantize color to closest color in the palette
    color = palette[index];

    fragcolor = vec4(color, 1.0f);
}
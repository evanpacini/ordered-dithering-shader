#version 450 compatibility

// Constants
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);
const mat4 bayerIndex = mat4(
00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0,
08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0,
02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0,
10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0
);

// Inputs
in vec4 texcoord;
uniform sampler2D gcolor;

// Outputs
out vec4 fragcolor;

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;
    float bayerValue = bayerIndex[int(gl_FragCoord.x) & 0x3][int(gl_FragCoord.y) & 0x3];
    float luminance = dot(grayscaleFactor, color.rgb);
    color.rgb = float(luminance > bayerValue).xxx;
    fragcolor = vec4(color.rgb, 1.0f);
}

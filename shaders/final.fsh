#version 450 compatibility

// Constants
const vec3 grayscaleFactor = vec3(0.2126, 0.7152, 0.0722);

// Inputs
in vec4 texcoord;
uniform sampler2D gcolor;
uniform sampler2D colortex15;

// Outputs
out vec4 fragcolor;

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;
    float thresh = texture2D(colortex15, gl_FragCoord.xy / 1024).r;
    float luminance = dot(grayscaleFactor, color.rgb);
    color.rgb = float(luminance > thresh).xxx;
    fragcolor = vec4(color.rgb, 1.0f);
}

#version 410 core

precision highp float;
precision highp vec4;
precision highp mat4;

in vec4 gl_FragCoord;
out vec4 frag_color;

uniform int maxiter;
uniform sampler1D palette;
uniform mat4 transform;

void main() {
    vec4 coord = transform * gl_FragCoord;
    float real = coord.x;
    float imag = coord.y;
    float const_real = real;
    float const_imag = imag;

    int iterations = 0;
    for (iterations = 0; iterations < maxiter; iterations++) {
        float tmp_real = real;
        real = (real * real - imag * imag) + const_real;
        imag = (2.0 * tmp_real * imag) + const_imag;
        float dist = real * real + imag * imag;
        if (dist > 4.0) break;
    }

    float iter = float(iterations) / maxiter * 255.0;
    frag_color = texture(palette, iter);
}

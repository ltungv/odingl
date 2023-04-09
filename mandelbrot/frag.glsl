#version 410 core

in highp vec4 gl_FragCoord;

out vec4 frag_color;

uniform sampler1D palette;
uniform highp mat4 transform;
uniform int maxiter;

void main() {
    highp vec4 coord = transform * gl_FragCoord;
    highp float real = coord.x;
    highp float imag = coord.y;
    highp float const_real = real;
    highp float const_imag = imag;

    int iterations = 0;
    for (iterations = 0; iterations < maxiter; iterations++) {
        highp float tmp_real = real;
        real = (real * real - imag * imag) + const_real;
        imag = (2.0 * tmp_real * imag) + const_imag;
        highp float dist = real * real + imag * imag;
        if (dist > 4.0) break;
    }

    if (iterations == maxiter) {
        frag_color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
    } else {
        float iter = float(iterations) / maxiter * 255.0;
        frag_color = texture(palette, iter);
    }
}

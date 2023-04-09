#version 410 core

in vec4 gl_FragCoord;

out vec4 frag_color;

uniform mat4 transform;
uniform int maxiter;

int get_iterations() {
    vec4 coord = transform * gl_FragCoord;
    float real = coord.x;
    float imag = coord.y;

    int iterations = 0;
    float const_real = real;
    float const_imag = imag;

    while (iterations < maxiter) {
        float tmp_real = real;
        real = (real * real - imag * imag) + const_real;
        imag = (2.0 * tmp_real * imag) + const_imag;
        float dist = real * real + imag * imag;
        if (dist > 4.0) break;
        ++iterations;
    }
    return iterations;
}

vec4 return_color() {
    int iter = get_iterations();
    if (iter == maxiter) {
        gl_FragDepth = 0.0f;
        return vec4(0.0f, 0.0f, 0.0f, 1.0f);
    }
    float iterations = float(iter) / maxiter;	
    return vec4(0.0f, iterations, 0.0f, 1.0f);
}

void main() {
    frag_color = return_color();
}

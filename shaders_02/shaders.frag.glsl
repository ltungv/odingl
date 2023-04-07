#version 410 core

// A fragment shader is for calculating the color output of our pixels. For simplicity,
// we keep using the same color.
out vec4 FragColor;

// Uniforms are global values that are shared by all shaders within the same shader program.
uniform vec4 ourColor;

void main() {
  // Colors are represent using RGBA format where values are between 0.0 and 1.0.
  FragColor = ourColor;
}

#version 410 core

// A fragment shader is for calculating the color output of our pixels. For simplicity,
// we keep using the same color.
out vec4 FragColor;

void main() {
  // Colors are represent using RGBA format where values are between 0.0 and 1.0.
  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}

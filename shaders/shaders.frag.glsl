#version 410 core

// A fragment shader is for calculating the color output of our pixels. For simplicity,
// we keep using the same color.
out vec4 FragColor;

// An input will received the value of an output produces by previous shaders.
// Values are passed between attributes having the same type and name.
in vec4 vertexColor;

void main() {
  // Colors are represent using RGBA format where values are between 0.0 and 1.0.
  FragColor = vertexColor;
}

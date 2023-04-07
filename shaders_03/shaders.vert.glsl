#version 410 core

// The vertex position
layout (location = 0) in vec3 aPos;
// The vertex color
layout (location = 1) in vec3 aColor;

// Output a color for the fragment shader to use.
out vec3 ourColor;

void main() {
  gl_Position = vec4(aPos, 1.0);
  ourColor = aColor;
}

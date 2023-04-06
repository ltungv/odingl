#version 410 core

// Define an input with the `in` keyword folowed by its type `vec3`. The location
// of the input `aPos` is set to 0.
layout (location = 0) in vec3 aPos;

void main() {
  // We're rendering in 3D so only the first 3 components of `gl_Position` are used
  // for the actual position. The `gl_Position.w` is used for something called
  // perspective division.
  //
  // Our shader do no processing and simply create a vertex at the given position.
  // Typically, input is not given in normalized device coordinates.
  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}

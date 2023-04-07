package main

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "../commons/"

SCREEN_TITLE :: "GLFW"
SCREEN_WIDTH :: 512
SCREEN_HEIGHT :: 512

gl_reset_viewport :: proc "c" (window: glfw.WindowHandle) {
  w, h := glfw.GetFramebufferSize(window)
  gl.Viewport(0, 0, w, h)
}

cb_frame_buffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  gl_reset_viewport(window)
}

cb_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
  if key == glfw.KEY_ESCAPE do glfw.SetWindowShouldClose(window, true)
}

main :: proc() {
  if glfw.Init() != 1 {
    fmt.println("Failed to initialize GLFW.") 
    return
  }
  defer glfw.Terminate()

  commons.glfw_window_hints()
  window := glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE, nil, nil)
  if window == nil {
    fmt.println("Failed to create window.")
    return
  }
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(1)
  glfw.SetKeyCallback(window, cb_key)
  glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)
  commons.gl_load()

  shader_program, is_program_ok := commons.gl_load_source(
    string(#load("shaders.vert.glsl")),
    string(#load("shaders.frag.glsl")));
  if !is_program_ok do return

  vao, vbo: u32
  vertices := [18]f32 {
    // 1st vertex
    0.5, -0.5, 0.0,
    // 1st vertex's color
    1.0, 0.0, 0.0,
    // 2nd vertex
    -0.5, -0.5, 0.0,
    // 2nd vertex's color
    0.0, 1.0, 0.0,
    // 3rd vertex
    0.0, 0.5, 0.0,
    // 3rd vertex's color
    0.0, 0.0, 1.0,
  };

  gl.GenVertexArrays(1, &vao)
  gl.BindVertexArray(vao)

  gl.GenBuffers(1, &vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  gl.BufferData(
    gl.ARRAY_BUFFER,
    size_of(vertices),
    &vertices,
    gl.STATIC_DRAW)

  // position attribute
  gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0);
  gl.EnableVertexAttribArray(0);
  // color attribute
  gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3* size_of(f32));
  gl.EnableVertexAttribArray(1);

  // Unbind VAO.
  gl.BindVertexArray(0)
  // Unbind VBO.
  gl.BindBuffer(gl.ARRAY_BUFFER, 0)

  for !glfw.WindowShouldClose(window) {
    // Check for user's inputs
    glfw.PollEvents()

    // Clear screen with color. Pink: 0.9, 0.2, 0.8.
    gl.ClearColor(0.2, 0.3, 0.3, 1.0) 
    gl.Clear(gl.COLOR_BUFFER_BIT)

    // Bind data.
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BindVertexArray(vao)

    // Draw triangles.
    gl.UseProgram(shader_program)
    gl.DrawArrays(gl.TRIANGLES, 0, 3)

    // Unbind data.
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    // OpenGL has 2 buffer where only 1 is active at any given time. When rendering,
    // we first modify the back buffer then swap it with the front buffer, where the
    // front buffer is the active one.
    glfw.SwapBuffers(window)
  }
}

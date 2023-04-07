package main

import "core:fmt"
import "core:math"
import "core:image/png"
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

load_texture_mipmap_from_file :: proc(texture_id: u32, path: string) {
  container_texture, container_texture_error := png.load_from_file(path)
  if container_texture_error != nil {
    fmt.println("Could not load texture image.")
    fmt.printf("Error: %s.\n", container_texture_error)
    return
  }
  defer png.destroy(container_texture)

  fmt.println(path)
  fmt.printf(
    "-- W: %d H: %d (%d pixels)\n",
    container_texture.width,
    container_texture.height,
    len(container_texture.pixels.buf))

  gl.BindTexture(gl.TEXTURE_2D, texture_id)
  gl.TexImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    i32(container_texture.width),
    i32(container_texture.height),
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    raw_data(container_texture.pixels.buf))
  gl.GenerateMipmap(gl.TEXTURE_2D)
}

main :: proc() {
  if glfw.Init() != 1 {
    fmt.println("Failed to initialize GLFW.") 
    return
  }
  defer glfw.Terminate()

  window, window_created := commons.glfw_window_create(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE)
  if !window_created do return
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(1)
  glfw.SetKeyCallback(window, cb_key)
  glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)
  commons.gl_load()

  shader_program, program_compiled := commons.gl_load_source(
    string(#load("shaders.vert.glsl")),
    string(#load("shaders.frag.glsl")));
  if !program_compiled do return

  textures: [2]u32
  gl.GenTextures(2, raw_data(&textures))
  load_texture_mipmap_from_file(textures[0], "textures/container.png")
  load_texture_mipmap_from_file(textures[1], "textures/awesomeface.png")

  vertices := [32]f32 {
    // 1st vertex positions, colors, and texture coordinates
    0.5, 0.5, 0.0,
    1.0, 0.0, 0.0,
    1.0, 1.0,
    // 2nd vertex positions, colors, and texture coordinates
    0.5, -0.5, 0.0,
    0.0, 1.0, 0.0,
    1.0, 0.0,
    // 3rd vertex positions, colors, and texture coordinates
    -0.5, -0.5, 0.0,
    0.0, 0.0, 1.0,
    0.0, 0.0,
    // 4th vertex positions, colors, and texture coordinates
    -0.5, 0.5, 0.0,
    1.0, 1.0, 0.0,
    0.0, 1.0
  }
  indices := [6]u32 {
    // 1st triangle
    0, 1, 3,
    // 2nd triangle
    1, 2, 3,
  }
  texture_coordinates := [6]f32 {
    // lower-left
    0.0, 0.0,
    // lower-right
    1.0, 0.0
    // top-center
    0.5, 1.0,
  }

  vao: u32
  gl.GenVertexArrays(1, &vao)
  gl.BindVertexArray(vao)

  vbo: u32
  gl.GenBuffers(1, &vbo)
  commons.gl_load_buffer_object_data(vbo, gl.ARRAY_BUFFER, gl.STATIC_DRAW, &vertices)

  ebo: u32
  gl.GenBuffers(1, &ebo)
  commons.gl_load_buffer_object_data(ebo, gl.ELEMENT_ARRAY_BUFFER, gl.STATIC_DRAW, &indices)

  // position attribute
  gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0);
  gl.EnableVertexAttribArray(0);
  // color attribute
  gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32));
  gl.EnableVertexAttribArray(1);
  // texture coordinate attribute
  gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32));
  gl.EnableVertexAttribArray(2);

  for !glfw.WindowShouldClose(window) {
    // Check for user's inputs
    glfw.PollEvents()

    // Container texture
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, textures[0])
    // Face texture
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, textures[1])
    // Bind opengl objects
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)

    // Set shaders
    gl.UseProgram(shader_program)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture1"), 0);
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture2"), 1);

    // Draw
    gl.ClearColor(0.2, 0.3, 0.3, 1.0) 
    gl.Clear(gl.COLOR_BUFFER_BIT)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))

    // OpenGL has 2 buffer where only 1 is active at any given time. When rendering,
    // we first modify the back buffer then swap it with the front buffer, where the
    // front buffer is the active one.
    glfw.SwapBuffers(window)
  }
}


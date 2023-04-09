package main

import "core:fmt"
import "core:math/linalg"
import "core:runtime"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "../commons"

zoom := f32(1.0)
xcenter := f32(0.0)
ycenter := f32(0.0)
transform := linalg.MATRIX4F32_IDENTITY

main :: proc() {
  if glfw.Init() != 1 {
    fmt.println("Could not initialize OpenGL.")
    return
  }
  defer glfw.Terminate()

  is_ok: bool
  window: glfw.WindowHandle
  if window, is_ok = commons.glfw_window_create(512, 512, "transformations"); !is_ok do return
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(1)
  glfw.SetKeyCallback(window, cb_key)
  glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)
  commons.gl_load()

  shader_program: u32
  if shader_program, is_ok = commons.gl_load_source(#load("vert.glsl"), #load("frag.glsl")); !is_ok do return

  vao, vbo, ebo: u32
  gl.GenVertexArrays(1, &vao)
  defer gl.DeleteVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)
  defer gl.DeleteBuffers(1, &vbo)
  gl.GenBuffers(1, &ebo)
  defer gl.DeleteBuffers(1, &ebo)

  quad_vertices, quad_indices := quad()
  gl.BindVertexArray(vao)
  // Load the vertices data
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_vertices), &quad_vertices, gl.STATIC_DRAW)
  // Load the indices data
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
  gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(quad_indices), &quad_indices, gl.STATIC_DRAW)

  // position attribute
  gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
  gl.EnableVertexAttribArray(0);

  for !glfw.WindowShouldClose(window) {
    // Accepting keyboard inputs for movement and zoom.
    glfw.PollEvents()
    handle_inputs(window)

    // Bind opengl objects
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)

    // Render
    gl.ClearColor(0.0, 0.0, 0.0, 1.0) 
    gl.Clear(gl.COLOR_BUFFER_BIT)

    gl.UseProgram(shader_program)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "transform"), 1, gl.FALSE, &transform[0][0]);
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "maxiter"), 1000);
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))

    glfw.SwapBuffers(window)
  }
}

cb_frame_buffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  w, h := glfw.GetFramebufferSize(window)
  gl.Viewport(0, 0, w, h)
  context = runtime.default_context()
  transform = matrix4_transform_mandelbrot_space(xcenter, ycenter, zoom, w, h)
}

cb_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
  if key == glfw.KEY_ESCAPE do glfw.SetWindowShouldClose(window, true)
}

handle_inputs :: proc(window: glfw.WindowHandle) {
  offset := 0.005 * zoom
  if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS do ycenter += offset
  if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS do ycenter -= offset
  if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS do xcenter -= offset
  if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS do xcenter += offset
  if glfw.GetKey(window, glfw.KEY_Q) == glfw.PRESS do zoom *= 1.02
  if glfw.GetKey(window, glfw.KEY_E) == glfw.PRESS do zoom *= 0.98

  context = runtime.default_context()
  w, h := glfw.GetFramebufferSize(window)
  transform = matrix4_transform_mandelbrot_space(xcenter, ycenter, zoom, w, h)
}

matrix4_transform_mandelbrot_space :: proc(xcenter, ycenter, zoom: f32, w, h: i32) -> linalg.Matrix4f32 {
  transform := linalg.MATRIX4F32_IDENTITY
  transform = transform * linalg.matrix4_scale(linalg.Vector3f32{4.5, 4.5, 1.0})
  transform = transform * linalg.matrix4_translate(linalg.Vector3f32{xcenter, ycenter, 1.0})
  transform = transform * linalg.matrix4_scale(linalg.Vector3f32{zoom, zoom, 1.0})
  transform = transform * linalg.matrix4_translate(linalg.Vector3f32{-0.5, -0.5, 1.0})
  transform = transform * linalg.matrix4_scale(linalg.Vector3f32{1.0 / f32(w), 1.0 / f32(h), 1.0})
  return transform
}

quad :: proc() -> ([12]f32, [6]u32) {
  vertices := [?]f32 {
     1.0,  1.0, 0.0,
     1.0, -1.0, 0.0,
    -1.0, -1.0, 0.0,
    -1.0,  1.0, 0.0
  }
  indices := [?]u32 {
      0, 1, 3,
      1, 2, 3,
  }
  return vertices, indices
}

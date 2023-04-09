package main

import "core:fmt"
import "core:image/png"
import "core:math/linalg"
import "core:runtime"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "../commons"

Application :: struct {
  maxiter: i32,
  zoom: f32,
  xcenter: f32,
  ycenter: f32,
  transform: linalg.Matrix4f32,
}

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

  app := Application {
    maxiter = 10000,
    zoom = f32(1.0),
    xcenter = f32(0.0),
    ycenter = f32(0.0),
    transform = linalg.MATRIX4F32_IDENTITY,
  }
  app_view_update(&app, window)

  glfw.SetWindowUserPointer(window, &app)
  glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)
  glfw.MakeContextCurrent(window)
  commons.gl_load()

  texture: u32
  gl.GenTextures(1, &texture)
  load_texture(texture, "mandelbrot/palette.png")

  shader_program: u32
  if shader_program, is_ok = commons.gl_load_source(#load("vert.glsl"), #load("frag.glsl")); !is_ok do return

  quad_vertices, quad_indices := quad()
  vao, vbo, ebo: u32
  gl.GenVertexArrays(1, &vao)
  defer gl.DeleteVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)
  defer gl.DeleteBuffers(1, &vbo)
  gl.GenBuffers(1, &ebo)
  defer gl.DeleteBuffers(1, &ebo)

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
    glfw.PollEvents()
    handle_inputs(window)

    gl.ClearColor(0.0, 0.0, 0.0, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)

    // Color texture
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_1D, texture)
    // Bind vertices buffers
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    // Draw shaders
    gl.UseProgram(shader_program)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "transform"), 1, gl.FALSE, &app.transform[0][0]);
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "maxiter"), app.maxiter);
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "palette"), 0);
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))

    glfw.SwapBuffers(window)
  }
}

cb_frame_buffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  context = runtime.default_context()
  app := cast(^Application) glfw.GetWindowUserPointer(window)
  w, h := glfw.GetFramebufferSize(window)

  gl.Viewport(0, 0, w, h)
  app_view_update(app, window)
}

handle_inputs :: proc(window: glfw.WindowHandle) {
  context = runtime.default_context()
  app := cast(^Application) glfw.GetWindowUserPointer(window)

  offset := 0.005 * app.zoom
  cached_zoom := app.zoom
  cached_xcenter := app.xcenter
  cached_ycenter := app.ycenter
  cached_maxiter := app.maxiter

  if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS do app.ycenter += offset
  if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS do app.ycenter -= offset
  if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS do app.xcenter -= offset
  if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS do app.xcenter += offset
  if glfw.GetKey(window, glfw.KEY_UP) == glfw.PRESS do app.zoom *= 0.98
  if glfw.GetKey(window, glfw.KEY_DOWN) == glfw.PRESS do app.zoom *= 1.02
  if glfw.GetKey(window, glfw.KEY_LEFT) == glfw.PRESS do app.maxiter -= 500
  if glfw.GetKey(window, glfw.KEY_RIGHT) == glfw.PRESS do app.maxiter += 500
  if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS do glfw.SetWindowShouldClose(window, true)

  is_view_changed := cached_zoom != app.zoom || cached_xcenter != app.xcenter || cached_ycenter != app.ycenter
  if is_view_changed do app_view_update(app, window)
  if cached_maxiter != app.maxiter do fmt.printf("Maxiter: %d\n", app.maxiter)
}

app_view_update :: proc(app: ^Application, window: glfw.WindowHandle) {
  w, h := glfw.GetFramebufferSize(window)
  transform := linalg.MATRIX4F32_IDENTITY
  transform = transform * linalg.matrix4_scale(linalg.Vector3f32{4.5, 4.5, 1.0})
  transform = transform * linalg.matrix4_translate(linalg.Vector3f32{app.xcenter, app.ycenter, 1.0})
  transform = transform * linalg.matrix4_scale(linalg.Vector3f32{app.zoom, app.zoom, 1.0})
  transform = transform * linalg.matrix4_translate(linalg.Vector3f32{-0.6, -0.5, 1.0})
  transform = transform * linalg.matrix4_scale(linalg.Vector3f32{1.0 / f32(w), 1.0 / f32(h), 1.0})
  app.transform = transform
}

load_texture :: proc(texture_id: u32, path: string) {
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

  gl.BindTexture(gl.TEXTURE_1D, texture_id)
  gl.TexImage1D(
    gl.TEXTURE_1D,
    0,
    gl.RGB,
    i32(container_texture.width),
    0,
    gl.RGB,
    gl.UNSIGNED_BYTE,
    raw_data(container_texture.pixels.buf))
  gl.TexParameteri(gl.TEXTURE_1D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_1D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
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

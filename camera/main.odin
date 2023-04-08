package main

import "core:fmt"
import "core:image/png"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "../commons"

delta_time := 0.0
last_frame := 0.0

fov := f32(45.0)
yaw := f32(-90.0)
pitch := f32(0.0)

mouse_first := true
mouse_last_x := f32(0.0)
mouse_last_y := f32(0.0)

camera_position := linalg.Vector3f32{0.0, 0.0, 3.0}
camera_front := linalg.Vector3f32{0.0, 0.0, -1.0}
camera_up := linalg.Vector3f32{0.0, 1.0, 0.0}

main :: proc() {
  if glfw.Init() != 1 {
    fmt.println("Could not initialize OpenGL.")
    return
  }
  defer glfw.Terminate()

  is_ok: bool
  window: glfw.WindowHandle
  window, is_ok = commons.glfw_window_create(800, 600, "camera")
  if !is_ok do return
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(1)
  glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
  glfw.SetKeyCallback(window, cb_key)
  glfw.SetCursorPosCallback(window, cb_mouse)
  glfw.SetScrollCallback(window, cb_scroll)
  glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)

  commons.gl_load()
  gl.Enable(gl.DEPTH_TEST)

  textures: [2]u32
  gl.GenTextures(2, raw_data(&textures))
  load_texture_mipmap_from_file(textures[0], "textures/container.png")
  load_texture_mipmap_from_file(textures[1], "textures/awesomeface.png")

  shader_program: u32
  shader_program, is_ok = commons.gl_load_source(
    string(#load("camera.vert.glsl")),
    string(#load("camera.frag.glsl")));
  if !is_ok do return

  vertices := [?]f32 {
    -0.5, -0.5, -0.5, 0.0, 0.0,
     0.5, -0.5, -0.5, 1.0, 0.0,
     0.5,  0.5, -0.5, 1.0, 1.0,
     0.5,  0.5, -0.5, 1.0, 1.0,
    -0.5,  0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0,

    -0.5, -0.5,  0.5, 0.0, 0.0,
     0.5, -0.5,  0.5, 1.0, 0.0,
     0.5,  0.5,  0.5, 1.0, 1.0,
     0.5,  0.5,  0.5, 1.0, 1.0,
    -0.5,  0.5,  0.5, 0.0, 1.0,
    -0.5, -0.5,  0.5, 0.0, 0.0,

    -0.5,  0.5,  0.5, 1.0, 0.0,
    -0.5,  0.5, -0.5, 1.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5,  0.5, 0.0, 0.0,
    -0.5,  0.5,  0.5, 1.0, 0.0,

     0.5,  0.5,  0.5, 1.0, 0.0,
     0.5,  0.5, -0.5, 1.0, 1.0,
     0.5, -0.5, -0.5, 0.0, 1.0,
     0.5, -0.5, -0.5, 0.0, 1.0,
     0.5, -0.5,  0.5, 0.0, 0.0,
     0.5,  0.5,  0.5, 1.0, 0.0,

    -0.5, -0.5, -0.5, 0.0, 1.0,
     0.5, -0.5, -0.5, 1.0, 1.0,
     0.5, -0.5,  0.5, 1.0, 0.0,
     0.5, -0.5,  0.5, 1.0, 0.0,
    -0.5, -0.5,  0.5, 0.0, 0.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,

    -0.5,  0.5, -0.5, 0.0, 1.0,
     0.5,  0.5, -0.5, 1.0, 1.0,
     0.5,  0.5,  0.5, 1.0, 0.0,
     0.5,  0.5,  0.5, 1.0, 0.0,
    -0.5,  0.5,  0.5, 0.0, 0.0,
    -0.5,  0.5, -0.5, 0.0, 1.0
  }
  cube_positions := [?]linalg.Vector3f32 {
    linalg.Vector3f32{ 0.0,  0.0,  0.0},
    linalg.Vector3f32{ 2.0,  5.0, -15.0},
    linalg.Vector3f32{-1.5, -2.2, -2.5},
    linalg.Vector3f32{-3.8, -2.0, -12.3},
    linalg.Vector3f32{ 2.4, -0.4, -3.5},
    linalg.Vector3f32{-1.7,  3.0, -7.5},
    linalg.Vector3f32{ 1.3, -2.0, -2.5},
    linalg.Vector3f32{ 1.5,  2.0, -2.5},
    linalg.Vector3f32{ 1.5,  0.2, -1.5},
    linalg.Vector3f32{-1.3,  1.0, -1.5}
  }
  cube_rotate_axis := [?]linalg.Vector3f32 {
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
    linalg.Vector3f32{rand.float32(), rand.float32(), rand.float32()}
  }

  vao, vbo: u32
  gl.GenVertexArrays(1, &vao)
  defer gl.DeleteVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)
  defer gl.DeleteBuffers(1, &vbo)

  gl.BindVertexArray(vao)
  // Load the vertices data
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

  // position attribute
  gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0);
  gl.EnableVertexAttribArray(0);
  // texture coordinate attribute
  gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32));
  gl.EnableVertexAttribArray(1);

  for !glfw.WindowShouldClose(window) {
    // Check for user's inputs
    glfw.PollEvents()
    process_input(window)

    current_frame := glfw.GetTime()
    delta_time = current_frame - last_frame
    last_frame = current_frame

    view := linalg.matrix4_look_at(camera_position, camera_position + camera_front, camera_up);
    proj := linalg.matrix4_perspective(linalg.radians(fov), 4.0 / 3.0, 0.1, 100.0)

    // Container texture
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, textures[0])
    // Face texture
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, textures[1])
    // Bind opengl objects
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    // Render
    gl.ClearColor(0.2, 0.3, 0.3, 1.0) 
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    gl.UseProgram(shader_program)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture1"), 0);
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture2"), 1);
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "view"), 1, gl.FALSE, &view[0][0]);
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "proj"), 1, gl.FALSE, &proj[0][0]);

    for index in 0..<10 {
      model := linalg.MATRIX4F32_IDENTITY
      model = model * linalg.matrix4_translate(cube_positions[index])
      model = model * linalg.matrix4_rotate(
        f32(glfw.GetTime()) * linalg.radians(f32(index + 1) * 20.0),
        cube_rotate_axis[index])

      gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "model"), 1, gl.FALSE, &model[0][0]);
      gl.DrawArrays(gl.TRIANGLES, 0, 36)
    }

    // OpenGL has 2 buffer where only 1 is active at any given time. When rendering,
    // we first modify the back buffer then swap it with the front buffer, where the
    // front buffer is the active one.
    glfw.SwapBuffers(window)
  }
}

cb_frame_buffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  w, h := glfw.GetFramebufferSize(window)
  gl.Viewport(0, 0, w, h)
}

cb_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
  if key == glfw.KEY_ESCAPE do glfw.SetWindowShouldClose(window, true)
}

cb_mouse :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
  context = runtime.default_context()
  if mouse_first {
    mouse_last_x = f32(xpos)
    mouse_last_y = f32(ypos)
    mouse_first = false
  }

  offset_x := f32(xpos) - mouse_last_x
  offset_y := f32(ypos) - mouse_last_y
  mouse_last_x = f32(xpos)
  mouse_last_y = f32(ypos)

  sensitivity := f32(0.1)
  yaw += sensitivity * offset_x
  pitch -= sensitivity * offset_y

  if pitch > 89.0 do pitch = 89.0
  if pitch < -89.0 do pitch = -89.0

  camera_front = linalg.normalize(linalg.Vector3f32{
    math.cos(linalg.radians(yaw)) * math.cos(linalg.radians(pitch)),
    math.sin(linalg.radians(pitch)),
    math.sin(linalg.radians(yaw)) * math.cos(linalg.radians(pitch)),
  })
}

cb_scroll :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
  fov -= f32(yoffset);
  if fov < 1.0 do fov = 1.0
  if fov > 45.0 do fov = 45.0
}

process_input :: proc(window: glfw.WindowHandle) {
  camera_speed := 2.5 * f32(delta_time)
  if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS do camera_position += camera_speed * camera_front
  if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS do camera_position -= camera_speed * camera_front
  if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS do camera_position -= camera_speed * linalg.normalize(linalg.cross(camera_front, camera_up))
  if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS do camera_position += camera_speed * linalg.normalize(linalg.cross(camera_front, camera_up))
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

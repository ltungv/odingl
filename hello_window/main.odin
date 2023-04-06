package main

import "core:c"
import "core:fmt"
import "core:time"
import "core:math"
import gl "vendor:OpenGL"
import "vendor:glfw"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 1

SCREEN_TITLE :: "GLFW"
SCREEN_WIDTH :: 512
SCREEN_HEIGHT :: 512

// Definition for OpenGL object param get procedure.
GlGetParamProc :: proc "cdecl" (object_id: u32, param_type: u32, param: [^]i32)

// Definition for OpenGL information log message get procedure.
GlGetInfoLogProc :: proc "cdecl" (object_id: u32, max_length: i32, get_length: ^i32, info_log: [^]u8)

// Set the viewport of OpenGL such that it covers the entire window.
gl_reset_viewport :: proc "c" (window: glfw.WindowHandle) {
  w, h := glfw.GetFramebufferSize(window)
  gl.Viewport(0, 0, w, h)
}

// Check for OpenGL error where the error status and message are retrieved by the given procedures.
gl_check_error :: proc(object_id: u32, status_param_id: u32, get_param: GlGetParamProc, get_info_log: GlGetInfoLogProc) -> bool {
  // Check status and return error if there's no error.
  status: i32
  get_param(object_id, status_param_id, &status)
  if status != 0 do return true
  // Get the error message length 
  info_log_length: i32
  get_param(object_id, gl.INFO_LOG_LENGTH, &info_log_length)
  // Allocate a buffer with the same size.
  info_log := make([]u8, info_log_length)
  defer delete(info_log)
  // Copy the error message into our buffer.
  get_info_log(object_id, info_log_length, nil, &info_log[0])
  fmt.printf("ERROR: %s\n", info_log)
  return false
}

// Compile the shader source located at the given file path.
gl_compile_source :: proc(source: string, $shader_type: u32) -> (u32, bool) {
  // Compile source.
  source_copy := cstring(raw_data(source))
  shader_id := gl.CreateShader(shader_type)
  gl.ShaderSource(shader_id, 1, &source_copy, nil)
  gl.CompileShader(shader_id)
  // Report errors.
  is_ok := gl_check_error(shader_id, gl.COMPILE_STATUS, gl.GetShaderiv, gl.GetShaderInfoLog)
  return shader_id, is_ok
}

// Compile the given vertex shader and fragment shader and link them to a new shader program.
gl_load_source :: proc(vert_source, frag_source: string) -> (program_id: u32, is_ok: bool) {
  // Compile the vertex shader and fragment shader source.
	vert_shader_id := gl_compile_source(vert_source, gl.VERTEX_SHADER) or_return
	defer gl.DeleteShader(vert_shader_id)
	frag_shader_id := gl_compile_source(frag_source, gl.FRAGMENT_SHADER) or_return
	defer gl.DeleteShader(frag_shader_id)
  // Attach shaders and link program.
  program_id = gl.CreateProgram()
  gl.AttachShader(program_id, vert_shader_id)
  gl.AttachShader(program_id, frag_shader_id)
  gl.LinkProgram(program_id)
  // Check for link errors.
  is_ok = gl_check_error(program_id, gl.LINK_STATUS, gl.GetProgramiv, gl.GetProgramInfoLog)
  return program_id, is_ok
}

cb_frame_buffer_size :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  // Reset the viewport if the window's size is changed.
  gl_reset_viewport(window)
}

cb_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
  // Exit program on escape pressed
  if key == glfw.KEY_ESCAPE do glfw.SetWindowShouldClose(window, true)
}

main :: proc() {
  // Initialize GLFW.
  if glfw.Init() != 1 {
    fmt.println("Failed to initialize GLFW.") 
    return
  }
  defer glfw.Terminate()

  // Choose opengl version.
  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
  // Only use opengl core functionalities.
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  // Enable forwrd compatibility (only required on MacOS).
  when ODIN_OS == .Darwin do glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1)

  // Create a render window.
  window := glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_TITLE, nil, nil)
  if window == nil {
    fmt.println("Failed to create window.")
    return
  }
  defer glfw.DestroyWindow(window)

  // Use window in current context.
  glfw.MakeContextCurrent(window)
  // Enable vsync.
  glfw.SwapInterval(1)
  // Set callbacks.
  glfw.SetKeyCallback(window, cb_key)
  glfw.SetFramebufferSizeCallback(window, cb_frame_buffer_size)

  // Load opengl function pointers, which are determined by the operating system.
  gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
  fmt.printf("OpenGL version: %s\n", gl.GetString(gl.VERSION));

  // Compile and link the shader program.
  shader_program, is_program_ok := gl_load_source(
    string(#load("hello_window.vert.glsl")),
    string(#load("hello_window.frag.glsl")));
  if !is_program_ok do return

  // A vertex array object (VAO) can be bound and any subsequent vertex attribute calls
  // will be stored inside the VAO. This means we only have to setup the VAO once, and
  // whenever we want to draw the object, we can just bind the corresponding VAO.
  vao: u32
  gl.GenVertexArrays(1, &vao)
  gl.BindVertexArray(vao)

  // Coordinates for the 4 vertices that compose the 2 triangles that make up a quad.
  // OpenGL use normalized coordinates that range between [-1, 1].
  vertices := [12]f32 {
    // 1st vertex
    0.5, 0.5, 0.0,
    // 2nd vertex
    0.5, -0.5, 0.0,
    // 3rd vertex
    -0.5, -0.5, 0.0,
    // 4th vertex
    -0.5, 0.5, 0.0
  };

  // Create one vertex buffer object (VBO). Any buffer calls we make (on the GL_ARRAY_BUFFER target)
  // will be used to configure the currently bound buffer, which is VBO.
  vbo: u32
  gl.GenBuffers(1, &vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  // Copy the coordinates above into the array buffer.
  // + GL_STREAM_DRAW: the data is set only once and used by the GPU at most a few times.
  // + GL_STATIC_DRAW: the data is set only once and used many times.
  // + GL_DYNAMIC_DRAW: the data is changed a lot and used many times.
  gl.BufferData(
    gl.ARRAY_BUFFER,
    size_of(vertices),
    &vertices,
    gl.STATIC_DRAW)

  // A list of vertex indices that are used to make the triangles.
  indices := [6]u32 {
    // First triangle
    0, 1, 3,
    // Second triangle
    1, 2, 3,
  }

  // An element buffer object (EBO) stores indices that OpenGL uses to decide that vertices to draw.
  ebo: u32
  gl.GenBuffers(1, &ebo)
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
  // Copy the indices into the buffer.
  gl.BufferData(
    gl.ELEMENT_ARRAY_BUFFER,
    size_of(indices),
    &indices,
    gl.STATIC_DRAW)

  // Tell OpenGL how the vertex data should be interpreted.
  // We're using a 9-element array of i32s to represent 3 vertices.
  gl.VertexAttribPointer(
    0, // input start at index 0.
    3, // each vertex contains 3 elements.
    gl.FLOAT, // vertex coordinates are given as floats.
    gl.FALSE, // whether we need to normalize the coordinates.
    3 * size_of(f32), // stride of 12 bytes (3 * 32bit = 3 * 4bytes)..
    0) // offset into VBO.
  // Enable the vertex attribute at the given VBO offset.
  gl.EnableVertexAttribArray(0)

  // Unbind VAO.
  gl.BindVertexArray(0)
  // Unbind EBO.
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
  // Unbind VBO.
  gl.BindBuffer(gl.ARRAY_BUFFER, 0)

  // Timer for background color osscilation.
  watch: time.Stopwatch
  time.stopwatch_start(&watch)

  for !glfw.WindowShouldClose(window) {
    // Check for user's inputs
    glfw.PollEvents()

    // Create oscillating value (osl).
    raw_duration := time.stopwatch_duration(watch)
    secs := f32(time.duration_seconds(raw_duration))
    osl := (math.sin(3 * secs) + 1) * 0.5

    // Clear screen with color. Pink: 0.9, 0.2, 0.8.
    gl.ClearColor(0.9 * osl, 0.2, 0.8, 1) 
    gl.Clear(gl.COLOR_BUFFER_BIT)

    // Bind data.
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BindVertexArray(vao)

    // Draw triangles.
    gl.UseProgram(shader_program)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))

    // Unbind data.
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    // OpenGL has 2 buffer whether only 1 is active at any given time. When rendering,
    // we first modify the back buffer then swap it with the front buffer, where the
    // front buffer is the active one.
    glfw.SwapBuffers(window)
  }
}

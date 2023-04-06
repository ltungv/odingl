package commons

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 1

// Definition for OpenGL object param get procedure.
GlGetParamProc :: proc "cdecl" (object_id: u32, param_type: u32, param: [^]i32)

// Definition for OpenGL information log message get procedure.
GlGetInfoLogProc :: proc "cdecl" (object_id: u32, max_length: i32, get_length: ^i32, info_log: [^]u8)

glfw_window_hints :: proc() {
  // Choose opengl version.
  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
  // Only use opengl core functionalities.
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  // Enable forwrd compatibility (only required on MacOS).
  when ODIN_OS == .Darwin do glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
}

gl_load :: proc() {
  gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
  fmt.printf("OpenGL version: %s\n", gl.GetString(gl.VERSION));
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

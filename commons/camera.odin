package commons

import "core:math"
import "core:math/linalg"

GlCamera :: struct {
  position: linalg.Vector3f32,
  front: linalg.Vector3f32,
  up: linalg.Vector3f32,
  fov: f32,
  pitch: f32,
  yaw: f32,
  speed: f32,
  sensitivity: f32,
}

gl_camera_get_view :: proc (camera: ^GlCamera) -> linalg.Matrix4f32 {
  return linalg.matrix4_look_at(camera.position, camera.position + camera.front, camera.up);
}

gl_camera_get_proj :: proc(camera: ^GlCamera, ratio, near, far: f32) -> linalg.Matrix4f32 {
  return linalg.matrix4_perspective(linalg.radians(camera.fov), ratio, near, far)
}

gl_camera_move_forward :: proc (camera: ^GlCamera, delta_time: f32) {
  camera.position += camera.speed * delta_time * camera.front
}

gl_camera_move_backward :: proc (camera: ^GlCamera, delta_time: f32) {
  camera.position -= camera.speed * delta_time * camera.front
}

gl_camera_move_left :: proc(camera: ^GlCamera, delta_time: f32) {
  camera.position -= camera.speed * delta_time * linalg.normalize(linalg.cross(camera.front, camera.up))
}

gl_camera_move_right :: proc(camera: ^GlCamera, delta_time: f32) {
  camera.position += camera.speed * delta_time * linalg.normalize(linalg.cross(camera.front, camera.up))
}

gl_camera_move_up :: proc(camera: ^GlCamera, delta_time: f32) {
  camera.position += camera.speed * delta_time * camera.up
}

gl_camera_move_down :: proc(camera: ^GlCamera, delta_time: f32) {
  camera.position -= camera.speed * delta_time * camera.up
}

gl_camera_pane :: proc(camera: ^GlCamera, mouse: ^GlMouse) {
  offset := gl_mouse_offset(mouse)
  camera.yaw += camera.sensitivity * offset.x
  camera.pitch -= camera.sensitivity * offset.y
  camera.pitch = math.min(camera.pitch, 89.0)
  camera.pitch = math.max(camera.pitch, -89.0)
  camera.front = linalg.normalize(linalg.Vector3f32{
    math.cos(linalg.radians(camera.yaw)) * math.cos(linalg.radians(camera.pitch)),
    math.sin(linalg.radians(camera.pitch)),
    math.sin(linalg.radians(camera.yaw)) * math.cos(linalg.radians(camera.pitch)),
  })
}

gl_camera_zoom :: proc(camera: ^GlCamera, offset: f32) {
  camera.fov -= offset;
  camera.fov = math.max(camera.fov, 1.0)
  camera.fov = math.min(camera.fov, 45.0)
}

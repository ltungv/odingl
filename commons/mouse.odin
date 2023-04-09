package commons

import "core:math"
import "core:math/linalg"

GlMouse :: struct {
  first: bool,
  pos_last: linalg.Vector2f32,
  pos_curr: linalg.Vector2f32,
}

gl_mouse_move :: proc(mouse: ^GlMouse, xpos, ypos: f32) {
  pos_new := linalg.Vector2f32{xpos, ypos}
  if mouse.first {
    mouse.pos_last = pos_new
    mouse.first = false
  } else {
    mouse.pos_last = mouse.pos_curr
  }
  mouse.pos_curr = pos_new
}

gl_mouse_offset :: proc(mouse: ^GlMouse) -> linalg.Vector2f32 {
  return mouse.pos_curr - mouse.pos_last
}

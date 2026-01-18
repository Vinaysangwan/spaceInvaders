package main

import "core:strings"
import "vendor:glfw"
import "core:fmt"

// #############################################################################
//                           Constants
// #############################################################################

// #############################################################################
//                           Structs
// #############################################################################
Button :: struct
{
  spriteID :SpriteID,
  rect :Rect,
  is_pressed :bool
}

// #############################################################################
//                           Globals
// #############################################################################
ui_string_builder :strings.Builder
FPS :i32

// #############################################################################
//                           Functions
// #############################################################################
button_pressed :: proc(button :^Button, mouse_button :i32 = glfw.MOUSE_BUTTON_LEFT) -> bool
{
  hover := button_hover(button)

  if(hover && mouse_pressed(mouse_button))
  {
    button.is_pressed = true
    button.rect.pos.y += 2
  }

  if(mouse_released(mouse_button))
  {
    if(button.is_pressed)
    {
      button.rect.pos.y -= 2
      button.is_pressed = false

      if(hover)
      {
        return true
      }
    }
  }

  return false
}

button_hover :: proc(button :^Button) -> bool
{
  return collision_Rect_Point(&button.rect, mouse_pos())
}

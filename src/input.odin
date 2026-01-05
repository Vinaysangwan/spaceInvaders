package main

import "base:runtime"
import "core:c"
import "vendor:glfw"

// #############################################################################
//                           Constants
// #############################################################################
MAX_KEY_COUNT :: glfw.KEY_LAST + 1
MAX_MOUSE_BUTTON_COUNT :: glfw.MOUSE_BUTTON_LAST + 1

// #############################################################################
//                           Structs
// #############################################################################
Keyboard :: struct
{
  currentKeys :[MAX_KEY_COUNT]bool,
  prevKeys :[MAX_KEY_COUNT]bool
}

Mouse :: struct
{
  currentButtons :[MAX_MOUSE_BUTTON_COUNT]bool,
  prevButtons :[MAX_MOUSE_BUTTON_COUNT]bool,
  x :f32,
  y :f32
}

InputState :: struct
{
  windowSize :IVec2,
  keyboard :Keyboard,
  mouse :Mouse
}

// #############################################################################
//                           Globals
// #############################################################################
inputState :InputState

// #############################################################################
//                           Functions
// #############################################################################
glfw_key_callback :: proc "c" (window :glfw.WindowHandle, key, scancode, action, mods :c.int)
{
  if(key >= 0 && key < MAX_KEY_COUNT)
  {
    if (action == glfw.PRESS)
    {
      inputState.keyboard.currentKeys[key] = true
    }
    else if(action == glfw.RELEASE)
    {
      inputState.keyboard.currentKeys[key] = false
    }
  }
}

key_down :: proc(key :i32) -> bool
{
  return inputState.keyboard.currentKeys[key]
}

key_pressed :: proc(key :i32) -> bool
{
  return !inputState.keyboard.prevKeys[key] && inputState.keyboard.currentKeys[key]
}

key_released :: proc(key :i32) -> bool
{
  return inputState.keyboard.prevKeys[key] && !inputState.keyboard.currentKeys[key]
}

glfw_mouse_button_callback :: proc "c" (window :glfw.WindowHandle, button, action, mods :c.int)
{
  if (action == glfw.PRESS)
  {
    inputState.mouse.currentButtons[button] = true
  }
  else if(action == glfw.RELEASE)
  {
    inputState.mouse.currentButtons[button] = false
  }
}

glfw_mouse_pos_callback :: proc "c" (window :glfw.WindowHandle, xPos, yPos :f64)
{
  inputState.mouse.x = f32(xPos)
  inputState.mouse.y = f32(yPos)
}

mouse_down :: proc(button :i32) -> bool
{
  return inputState.mouse.currentButtons[button]  
}

mouse_pressed :: proc(button :i32) -> bool
{
  return !inputState.mouse.prevButtons[button] && inputState.mouse.currentButtons[button]
}

mouse_released :: proc(button :i32) -> bool
{
  return inputState.mouse.prevButtons[button] && !inputState.mouse.currentButtons[button]
}

mouse_pos :: proc() -> Vec2
{
  return Vec2{inputState.mouse.x, inputState.mouse.y}
}

mouse_xPos :: proc() -> f32
{
  return inputState.mouse.x
}

mouse_yPos :: proc() -> f32
{
  return inputState.mouse.y
}

input_end_frame :: proc()
{
  for i := 0; i < MAX_KEY_COUNT; i += 1
  {
    inputState.keyboard.prevKeys[i] = inputState.keyboard.currentKeys[i]
  }

  for i := 0; i < MAX_MOUSE_BUTTON_COUNT; i += 1
  {
    inputState.mouse.prevButtons[i] = inputState.mouse.currentButtons[i]
  }
}

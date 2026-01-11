package main

import "core:fmt"
import "base:runtime"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "vendor:stb/image"

// #############################################################################
//                           Globals
// #############################################################################
window :glfw.WindowHandle
running := true

// #############################################################################
//                           Functions
// #############################################################################
error_callback :: proc "c" (error :i32, msg :cstring)
{
  context = runtime.default_context()
  SM_ERROR("GLFW_ERROR[%d]: %s", error, msg)
}

framebuffer_size_callback :: proc "c" (window :glfw.WindowHandle, width, height :i32)
{
  gl.Viewport(0, 0, width, height)
}

window_create :: proc(title: cstring, width, height: i32, isResizable: bool) -> bool
{
  // Set GLFW Error Callback
  glfw.SetErrorCallback(error_callback)
  
  // Init GLFW
  if(!glfw.Init())
  {
    fmt.println("Error::Failed to Init GLFW");
    return false;
  }

  // GLFW Window Hints
  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  glfw.WindowHint(glfw.RESIZABLE, i32(isResizable))
  glfw.WindowHint(glfw.VISIBLE, glfw.FALSE)

  // Create Window
  window = glfw.CreateWindow(width, height, title, nil, nil)
  if (window == nil)
  {
    fmt.println("Error:: Failed to Create Window")
    return false
  }
  glfw.MakeContextCurrent(window)

  inputState.windowSize = IVec2{x = width, y = height}

  // Set Window Pos
  vdMode := glfw.GetVideoMode(glfw.GetPrimaryMonitor())
  glfw.SetWindowPos(window, (vdMode.width - width) / 2, 40)

  // Set glfw Callbacks
  glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
  glfw.SetKeyCallback(window, glfw_key_callback)
  glfw.SetMouseButtonCallback(window, glfw_mouse_button_callback)
  glfw.SetCursorPosCallback(window, glfw_mouse_pos_callback)
  
  // Make Window Visible
  glfw.ShowWindow(window)
  
  return true;
}

enable_vSync :: proc(vSync :bool)
{
  glfw.SwapInterval(i32(vSync))
}

window_update :: proc()
{
  if (glfw.WindowShouldClose(window))
  {
    running = false
  }

  glfw.PollEvents()
}

window_swap_buffers :: proc()
{
  glfw.SwapBuffers(window)
}

window_set_icon :: proc(iconFilePath :cstring)
{
  width, height, nChannels :i32
  img := image.load(iconFilePath, &width, &height, &nChannels, 4)

  icon :glfw.Image
  icon.width = width
  icon.height = height
  icon.pixels = img

  glfw.SetWindowIcon(window, []glfw.Image{icon})
  image.image_free(img)
}

window_cleanup :: proc()
{
  glfw.SetErrorCallback(nil)
  
  glfw.DestroyWindow(window)
  glfw.Terminate()
}

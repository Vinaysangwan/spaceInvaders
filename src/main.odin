package main

import "vendor:glfw"

// #############################################################################
//                           Constants
// #############################################################################
UPDATE_DELAY :: 60
UPDATE_TIMER :: 1.0 / UPDATE_DELAY

main :: proc()
{
  // Window Creation
  if(!window_create("Space Invaders", 1280, 720, true))
  {
    return
  }
  defer window_cleanup()  

  window_set_icon("assets/textures/window_icon.png")
  enable_vSync(false)

  // Init OpenGL
  if(!gl_init())
  {
    SM_ERROR("Failed to Setup OpenGL")
    return
  }

  // Init Audio
  audio_init()
  defer audio_cleanup()

  // Init Game
  game_init()
  defer game_cleanup()

  lastTime := glfw.GetTime()
  currentTime := 0.0
  dt :f32 = 0.0
  accumulatedTime :f32 = 0.0
  alpha :f32 = 0.0
  fps_counter :i32 = 0
  fps_timer :f32 = 0.0
  
  // Main Game Loop
  for (running)
  {
    // Delta Time Calculation
    currentTime = glfw.GetTime()
    dt = f32(currentTime - lastTime)
    lastTime = currentTime

    // FPS Calculation
    fps_counter += 1
    fps_timer += dt
    if (fps_timer >= 1.0)
    {
      FPS = fps_counter
      fps_counter = 0
      fps_timer -= 1.0
    }

    window_update()

    // Physics Loop
    accumulatedTime += dt
    for accumulatedTime >= UPDATE_TIMER
    {
      accumulatedTime -= UPDATE_TIMER

      // Update Game
      game_update(UPDATE_TIMER)

      input_end_frame()
    }

    // Draw Game
    alpha = clamp(accumulatedTime / UPDATE_TIMER, 0.0, 1.0)
    game_render(alpha)
    gl_render()
    
    window_swap_buffers()
  }
}

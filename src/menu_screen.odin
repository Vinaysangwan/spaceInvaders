package main

import "vendor:glfw"

// #############################################################################
//                          Constants 
// #############################################################################

// #############################################################################
//                          Structs
// #############################################################################
MenuScreen :: struct
{
  // Buttons
  playButton :Button,
  quitButton :Button,

  // Audio
  bg_music_ID :SoundID
}

// #############################################################################
//                          Functions
// #############################################################################
menuScreen_init :: proc(menuScreen :^MenuScreen)
{
  // Init Play Button
  menuScreen.playButton = {
    spriteID = SpriteID.BUTTON_PLAY,
    rect = {pos = {f32(inputState.windowSize.x) / 2, 300}, size = {128, 64}}
  }

  // Init Quit Button
  menuScreen.quitButton = {
    spriteID = SpriteID.BUTTON_QUIT,
    rect = {pos = {f32(inputState.windowSize.x) / 2, 400}, size = {128, 64}}
  }

  // Init BG Music ID
  menuScreen.bg_music_ID = SoundID.BG_MENU
}

menuScreen_update :: proc(menuScreen :^MenuScreen, dt :f32)
{
  // Play BG Music
  audio_play(menuScreen.bg_music_ID, true)
  
  // Switch Screens
  if(key_pressed(glfw.KEY_ESCAPE) || button_pressed(&menuScreen.quitButton))
  {
    running = false
  }
  else if(key_down(glfw.KEY_ENTER) || (button_pressed(&menuScreen.playButton)))
  {
    audio_stop(menuScreen.bg_music_ID)
    
    gameState.currentScreen = Screen.PLAY
    playScreen_init(&gameState.playScreen)    
  }
}

menuScreen_render :: proc(menuScreen :^MenuScreen, alpha :f32)
{
  set_background(SpriteID.BG_MENU)
  draw_ui_button(&menuScreen.playButton)
  draw_ui_button(&menuScreen.quitButton)
}

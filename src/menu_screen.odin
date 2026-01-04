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
  playButton :Button,
  quitButton :Button
}

// #############################################################################
//                          Functions
// #############################################################################
menuScreen_init :: proc(menuScreen :^MenuScreen)
{
  // Init Play Button
  menuScreen.playButton = {
    spriteID = SpriteID.BUTTON_PLAY,
    rect = {pos = {f32(inputState.windowSize.x) / 2, 200}, size = {108, 58}}
  }

  // Init Quit Button
  menuScreen.quitButton = {
    spriteID = SpriteID.BUTTON_QUIT,
    rect = {pos = {f32(inputState.windowSize.x) / 2, 400}, size = {108, 58}}
  }
}

menuScreen_update :: proc(menuScreen :^MenuScreen, dt :f32)
{
  // Switch Screens
  if(key_pressed(glfw.KEY_ESCAPE) || button_pressed(&menuScreen.quitButton))
  {
    running = false
  }
  else if(key_down(glfw.KEY_ENTER) || (button_pressed(&menuScreen.playButton)))
  {
    gameState.currentScreen = Screen.PLAY
    playScreen_init(&gameState.playScreen)    
  }
}

menuScreen_render :: proc(menuScreen :^MenuScreen, alpha :f32)
{
  set_background(SpriteID.BG_MENU)
  draw_sprite(menuScreen.playButton.spriteID, menuScreen.playButton.rect.pos)
  draw_sprite(menuScreen.quitButton.spriteID, menuScreen.quitButton.rect.pos)

  draw_rect(Vec2{100, 100}, Vec2{100, 100}, Vec4{255, 0, 0, 255})
}

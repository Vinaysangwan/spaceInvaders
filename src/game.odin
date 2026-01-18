package main

import "core:strings"
import "vendor:glfw"

// #############################################################################
//                           Constants
// #############################################################################
WORLD_WIDTH :: 320
WORLD_HEIGHT :: 180

// #############################################################################
//                           Structs
// #############################################################################
Screen :: enum
{
  MENU,
  PLAY
}

GameState :: struct
{
  currentScreen :Screen,
  menuScreen :MenuScreen,
  playScreen :PlayScreen,

  debugMode :bool
}

// #############################################################################
//                           Gloabls
// #############################################################################
gameState :GameState

// #############################################################################
//                           Functions
// #############################################################################
game_init :: proc()
{
  gameState.debugMode = false
  
  // Init Ui Stuff
  {
    ui_string_builder = strings.builder_make()
    FPS = 0
  }
  
  // Init Camera
  {
    // Game Camera
    gameCamera := &renderData.gameCamera
    gameCamera.zoom = 1.0
    gameCamera.pos = Vec2{WORLD_WIDTH / 2.0, -WORLD_HEIGHT / 2.0}
    gameCamera.dimensions = Vec2{WORLD_WIDTH, WORLD_HEIGHT}

    // UI Camera
    uiCamera := &renderData.uiCamera
    uiCamera.zoom = 1.0
    uiCamera.pos = Vec2{f32(inputState.windowSize.x) / 2.0, -f32(inputState.windowSize.y) / 2.0}
    uiCamera.dimensions = Vec2{f32(inputState.windowSize.x), f32(inputState.windowSize.y)}
  }

  // Init Screen
  gameState.currentScreen = Screen.MENU

  // Init Current Screen
  switch(gameState.currentScreen)
  {
  case Screen.MENU:
  {
    menuScreen_init(&gameState.menuScreen)
    
    break
  } 
  case Screen.PLAY:
  {
    playScreen_init(&gameState.playScreen)
    
    break
  }
  }
  
}

game_update :: proc(dt :f32)
{
  if (key_pressed(glfw.KEY_D))
  {
    gameState.debugMode = !gameState.debugMode
  }
  
  switch(gameState.currentScreen)
  {
  case Screen.MENU:
  {
    menuScreen_update(&gameState.menuScreen, dt)
    
    break
  } 
  case Screen.PLAY:
  {
    playScreen_update(&gameState.playScreen, dt)
    
    break
  }
  }
}

game_render :: proc(alpha :f32)
{
  switch(gameState.currentScreen)
  {
  case Screen.MENU:
  {
    menuScreen_render(&gameState.menuScreen, alpha)

    break
  } 
  case Screen.PLAY:
  {
    playScreen_render(&gameState.playScreen, alpha)
    
    break
  }
  }

  if (gameState.debugMode)
  {
    draw_ui_FPS(Vec2{f32(inputState.windowSize.x - 150), 16})
  }
}

game_cleanup :: proc()
{
  strings.builder_reset(&ui_string_builder)
  strings.builder_destroy(&ui_string_builder)
}

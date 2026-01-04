package main

import "vendor:glfw"

// #############################################################################
//                           Constants
// #############################################################################
MAX_ENEMY_COUNT_X :: 5
MAX_ENEMY_COUNT_Y :: 2
MAX_ENEMY_COUNT :: (MAX_ENEMY_COUNT_X * MAX_ENEMY_COUNT_Y)

// #############################################################################
//                           Structs
// #############################################################################
PlayScreen :: struct
{
  player :Player,
  enemies :[MAX_ENEMY_COUNT]Enemy
}

// #############################################################################
//                           Functions
// #############################################################################
playScreen_init :: proc(playScreen :^PlayScreen)
{
  // Init Player
  player_init(&playScreen.player)
  
  // Init Enemy
  for j: i32 = 0; j < MAX_ENEMY_COUNT_Y; j += 1
  {
    for i: i32 = 0; i < MAX_ENEMY_COUNT_X; i += 1
    {
      enemy_init(&playScreen.enemies[j * 5 + i], {f32(i * 32.0 + 16.0), f32(j * 32.0 + 16.0)})
    }
  }
}

playScreen_update :: proc(playScreen :^PlayScreen, dt :f32)
{
  // Change Current Screen
  if(key_pressed(glfw.KEY_ESCAPE))
  {
    gameState.currentScreen = Screen.MENU
    menuScreen_init(&gameState.menuScreen)
  }
  
  // Update Player
  player_update(&playScreen.player, dt) 

  // Update Enemies
  for i: i32 = 0; i < MAX_ENEMY_COUNT; i += 1
  {
    enemy_update(&playScreen.enemies[i], dt)
  }
}

playScreen_render :: proc(playScreen :^PlayScreen, alpha :f32)
{
  player_render(&playScreen.player, alpha)

  for i: i32 = 0; i < MAX_ENEMY_COUNT; i += 1
  {
    enemy_render(&playScreen.enemies[i], alpha)
  }
}

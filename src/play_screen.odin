package main

import "vendor:glfw"

// #############################################################################
//                           Constants
// #############################################################################
// Enemy
MAX_ENEMY_COUNT_X :: 5
MAX_ENEMY_COUNT_Y :: 2
MAX_ENEMY_COUNT :: (MAX_ENEMY_COUNT_X * MAX_ENEMY_COUNT_Y)

// Bomb
MAX_BOMB_COUNT :: 50
BOMB_DROP_TIMER :: 1.0

// #############################################################################
//                           Structs
// #############################################################################
Bomb :: struct
{
  pos :Vec2,
  prePos :Vec2
}

PlayScreen :: struct
{
  player :Player,
  enemies :Array(Enemy, MAX_ENEMY_COUNT),
  bomb :Array(Bomb, MAX_BOMB_COUNT),
  bomb_drop_timer :f32
}

// #############################################################################
//                           Functions
// #############################################################################
bomb_get_collison_area :: proc(bomb :^Bomb) -> Circle
{
  return Circle{bomb.pos, 3.5}
}

playScreen_init :: proc(playScreen :^PlayScreen)
{
  // Init Player
  player_init(&playScreen.player)
  
  // Init Enemy
  playScreen.enemies.count = MAX_ENEMY_COUNT
  for j: i32 = 0; j < MAX_ENEMY_COUNT_Y; j += 1
  {
    for i: i32 = 0; i < MAX_ENEMY_COUNT_X; i += 1
    {
      enemy_init(&playScreen.enemies.elements[j * 5 + i], {f32(i * 32.0 + 16.0), f32(j * 32.0 + 16.0)})
    }
  }

  playScreen.bomb_drop_timer = 0.0
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
  if(playScreen.player.alive)
  {
    player_update(&playScreen.player, dt) 
  }

  // Update Enemies
  for i: i32 = 0; i < playScreen.enemies.count; i += 1
  {
    enemy_update(&playScreen.enemies.elements[i], dt)
  }

  // Collision Between enemy and bullet
  bullet_idx :i32 = 0
  for bullet_idx < playScreen.player.bullets.count
  {
    enemy_idx :i32 = 0
    hit := false
    for enemy_idx < playScreen.enemies.count
    {
      enemy_rect := enemy_get_collision_area(&playScreen.enemies.elements[enemy_idx])
      bullet_rect := player_get_bullet_collision_area(&playScreen.player.bullets.elements[bullet_idx])
      
      if(collision_Rects(&enemy_rect, &bullet_rect))
      {
        hit = true
        Array_swap_remove(&playScreen.enemies, enemy_idx)
        break
      }
      else
      {
        enemy_idx += 1 
      }
    }

    if(hit)
    {
      Array_swap_remove(&playScreen.player.bullets, bullet_idx)
    }
    else
    {
      bullet_idx += 1
    }
  }

  // Collsion Between player and bombs
}

playScreen_render :: proc(playScreen :^PlayScreen, alpha :f32)
{
  if(playScreen.player.alive)
  {
    player_render(&playScreen.player, alpha)
  }

  for i: i32 = 0; i < playScreen.enemies.count; i += 1
  {
    enemy_render(&playScreen.enemies.elements[i], alpha)
  }
}

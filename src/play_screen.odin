package main

import fs "vendor:fontstash"
import "core:math/rand"
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
BOMB_SPEED :: 1.5

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
  bombs :Array(Bomb, MAX_BOMB_COUNT),
  bombDropTimer :f32,

  score :i32
}

// #############################################################################
//                           Functions
// #############################################################################
bomb_get_collision_area :: proc(bomb :^Bomb) -> Circle
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

  playScreen.bombDropTimer = 0.0

  playScreen.score = 0
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

  // Drop Bomb
  playScreen.bombDropTimer += dt
  if(playScreen.bombDropTimer >= BOMB_DROP_TIMER)
  {
    playScreen.bombDropTimer -= BOMB_DROP_TIMER

    if(playScreen.enemies.count > 0)
    {
      chosenEnemy := rand.choice(playScreen.enemies.elements[0:playScreen.enemies.count])

      bomb :Bomb
      bomb.pos = Vec2{chosenEnemy.pos.x, chosenEnemy.pos.y + 8}
      bomb.prePos = bomb.pos

      Array_add(&playScreen.bombs, &bomb)
    }
  }

  // Update Bombs & collision player and bombs
  bomb_idx :i32 = 0
  player := &playScreen.player
  player_collision_area := player_get_collision_area(player)
  for bomb_idx < playScreen.bombs.count
  {
    bomb := &playScreen.bombs.elements[bomb_idx]

    bomb.prePos.y = bomb.pos.y
    bomb.pos.y += BOMB_SPEED

    bomb_collision_area := bomb_get_collision_area(bomb)

    if(bomb.pos.y > WORLD_HEIGHT + 15)
    {
      Array_swap_remove(&playScreen.bombs, bomb_idx)
    }
    else if(player.alive && collision_Rect_Circle(&player_collision_area, &bomb_collision_area))
    {
      player_kill(player)
      SM_TRACE("Final Score: {}", playScreen.score)
      Array_swap_remove(&playScreen.bombs, bomb_idx)
    }
    else
    {
      bomb_idx += 1
    }
  }

  // Collision enemy and bullet
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
        playScreen.score += 1
        SM_TRACE("Score: {}", playScreen.score)
        
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
}

playScreen_render :: proc(playScreen :^PlayScreen, alpha :f32)
{
  // Render Background
  set_background(SpriteID.BG_PLAY)
  
  // Render Player
  if(playScreen.player.alive)
  {
    player_render(&playScreen.player, alpha)
  }

  // Render Enemies
  for i :i32 = 0; i < playScreen.enemies.count; i += 1
  {
    enemy_render(&playScreen.enemies.elements[i], alpha)
  }

  // Render Bombs
  for i :i32 = 0; i < playScreen.bombs.count; i += 1
  {
    bombRenderPos := lerp_vec2(alpha, playScreen.bombs.elements[i].prePos, playScreen.bombs.elements[i].pos)
    
    draw_sprite(SpriteID.BOMB, bombRenderPos)
  }
}

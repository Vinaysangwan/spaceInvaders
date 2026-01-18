package main

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

PlayState :: enum
{
  Play,
  Menu,
  GameOver,
  GameWon
}

PlayScreen :: struct
{
  state :PlayState,
  
  player :Player,
  enemies :Array(Enemy, MAX_ENEMY_COUNT),
  bombs :Array(Bomb, MAX_BOMB_COUNT),
  bombDropTimer :f32,

  score :i32,

  // Shared Buttons
  homeButton :Button,
  
  // Menu Buttons
  continueButton :Button,
  
  // Game Won Buttons
  playAgainButton :Button,
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
  // Init Play Screen State
  playScreen.state = PlayState.Play
  
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

  // Init Buttons
  {
    // Home Button
    playScreen.homeButton = Button{
      spriteID = SpriteID.BUTTON_HOME,
      rect = Rect{pos = Vec2{f32(inputState.windowSize.x) / 2, f32(inputState.windowSize.y) / 2 + 50}, size = Vec2{128, 64}}
    }

    // Continue Button
    playScreen.continueButton = Button{
      spriteID = SpriteID.BUTTON_CONTINUE,
      rect = Rect{pos = Vec2{f32(inputState.windowSize.x) / 2, f32(inputState.windowSize.y) / 2 - 50}, size = Vec2{128, 64}}
    }

    // Play Again Button
    playScreen.playAgainButton = Button{
      spriteID = SpriteID.BUTTON_PLAY_AGAIN,
      rect = Rect{pos = Vec2{f32(inputState.windowSize.x) / 2, f32(inputState.windowSize.y) / 2 - 50}, size = Vec2{128, 64}}
    }
  }
}

playScreen_update :: proc(playScreen :^PlayScreen, dt :f32)
{
  // Handle States
  switch(playScreen.state)
  {
  case PlayState.Play:
  {
    // Change to States
    if(key_pressed(glfw.KEY_ESCAPE))  // Menu
    {
      playScreen.state = PlayState.Menu
    }
    else if(playScreen.score == 10)   // Game Won
    {
      playScreen.player.won = true
      playScreen.player.pos.x = WORLD_WIDTH / 2
      playScreen.state = PlayState.GameWon
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
        Array_swap_remove(&playScreen.bombs, bomb_idx)

        audio_play(SoundID.DESTROY)
        playScreen.state = PlayState.GameOver
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
          
          Array_swap_remove(&playScreen.enemies, enemy_idx)
          audio_play(SoundID.DESTROY)
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

  case PlayState.Menu:
  {
    if (key_pressed(glfw.KEY_ENTER) || key_pressed(glfw.KEY_ESCAPE) || button_pressed(&playScreen.continueButton))
    {
      playScreen.state = PlayState.Play
    }
  }
  
  case PlayState.GameOver:
  {
    if (key_pressed(glfw.KEY_ENTER))
    {
      gameState.currentScreen = Screen.MENU
      menuScreen_init(&gameState.menuScreen)
    }
  }

  case PlayState.GameWon:
  {
    if (key_down(glfw.KEY_ENTER) || button_pressed(&playScreen.playAgainButton))
    {
      playScreen_init(playScreen)
    }
  }
  }
  
  if(playScreen.state != PlayState.Play)
  {
    if(button_pressed(&playScreen.homeButton))
    {
      gameState.currentScreen = Screen.MENU
      menuScreen_init(&gameState.menuScreen)
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

  if (playScreen.state != PlayState.Play)
  {
    draw_ui_sprite(SpriteID.UI_BLOCK, Vec2{f32(inputState.windowSize.x) / 2, f32(inputState.windowSize.y) / 2})

    draw_ui_button(&playScreen.homeButton)
  }

  switch(playScreen.state)
  {
  case PlayState.Play:
  {
    // Render Bombs
    for i :i32 = 0; i < playScreen.bombs.count; i += 1
    {
      bombRenderPos := lerp_vec2(alpha, playScreen.bombs.elements[i].prePos, playScreen.bombs.elements[i].pos)
      
      draw_sprite(SpriteID.BOMB, bombRenderPos)
    }

    draw_ui_format_text(Vec2{0, 16}, 2, Vec4{255, 0, 0, 255}, "Score: {}", playScreen.score)
  }

  case PlayState.Menu:
  {
    draw_ui_button(&playScreen.continueButton)

    draw_ui_text("Menu", Vec2{f32(inputState.windowSize.x) / 2 - 150, f32(inputState.windowSize.y) / 2 - 200}, 8)
  }
 
  case PlayState.GameOver:
  {
    draw_ui_text("Game Over", Vec2{f32(inputState.windowSize.x) / 2 - 250, f32(inputState.windowSize.y) / 2 - 200}, 8)
    draw_ui_format_text(
      Vec2{f32(inputState.windowSize.x) / 2 - 150, f32(inputState.windowSize.y) / 2 - 100}, 
      6, 
      Vec4{255, 0, 0, 255}, 
      "Score: {}", 
      playScreen.score
    )
  }
  
  case PlayState.GameWon:
  {
    draw_ui_button(&playScreen.playAgainButton)

    draw_ui_text("You WON!", Vec2{f32(inputState.windowSize.x) / 2 - 200, f32(inputState.windowSize.y) / 2 - 200}, 8)
    draw_ui_format_text(
      Vec2{f32(inputState.windowSize.x) / 2 - 150, f32(inputState.windowSize.y) / 2 - 100}, 
      6, 
      Vec4{255, 0, 0, 255}, 
      "Score: {}", 
      playScreen.score
    )
  }
  }
}

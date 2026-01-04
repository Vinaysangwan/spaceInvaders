package main

import "vendor:glfw"

// #############################################################################
//                          Constants 
// #############################################################################
MAX_BULLET_COUNT :: 300
BULLET_SPEED :: 2.5
SHOOT_COOLDOWN_TIME :: 0.2

// #############################################################################
//                          Structs
// #############################################################################
Bullet :: struct
{
  prevPos :Vec2,
  pos :Vec2,
}

Player :: struct
{
  spriteID :SpriteID,
  size :Vec2,

  prevPos :Vec2,
  pos :Vec2,

  movement :Vec2,
  speed :f32,

  bullets :Array(Bullet, MAX_BULLET_COUNT),
  shoot_timer :f32
}

// #############################################################################
//                          Functions 
// #############################################################################
player_init :: proc(player :^Player)
{
  player.spriteID = SpriteID.SHIP1
  player.size = ivec2_f(SPRITES[player.spriteID].size)

  player.pos = Vec2{WORLD_WIDTH / 2, WORLD_HEIGHT - player.size.y / 2}
  player.prevPos = player.pos
  player.movement = Vec2{0, 0}
  
  player.speed = 2

  player.bullets.count = 0
  player.shoot_timer = 0.0
}

player_update :: proc(player :^Player, dt :f32)
{
  player.movement = {0, 0}

  if(key_down(glfw.KEY_A))
  {
    player.movement.x -= player.speed
  }
  if(key_down(glfw.KEY_D))
  {
    player.movement.x += player.speed
  }

  // Move Player
  player.prevPos = player.pos
  player.pos.x = clamp(player.pos.x + player.movement.x, player.size.x / 2, WORLD_WIDTH - player.size.x / 2)

  // fire Bullets
  if(key_down(glfw.KEY_SPACE))
  {
    player.shoot_timer += dt
    for(player.shoot_timer >= SHOOT_COOLDOWN_TIME)
    {
      player.shoot_timer -= SHOOT_COOLDOWN_TIME

      // Spawn Bullets
      if(player.bullets.count < MAX_BULLET_COUNT)
      {
        bullet :Bullet
        bullet.pos = {player.pos.x, player.pos.y - 10}
        bullet.prevPos = bullet.pos
        Array_add(&player.bullets, &bullet)
      }
    }
  }

  // Update Bullets
  b :i32 = 0
  for b < player.bullets.count
  {
    player.bullets.elements[b].prevPos = player.bullets.elements[b].pos
    player.bullets.elements[b].pos.y -= BULLET_SPEED

    if (player.bullets.elements[b].pos.y <= -10)
    {
      Array_swap_remove(&player.bullets, b)
    }
    else
    {
      b += 1
    }
  }
}

player_render :: proc(player :^Player, alpha :f32)
{
  playerRenderPos := lerp_vec2(alpha, player.prevPos, player.pos)
  draw_sprite(player.spriteID, playerRenderPos)

  for i :i32=0; i<player.bullets.count; i+= 1
  {
    bullet := &player.bullets.elements[i]

    bulletRenderPos := lerp_vec2(alpha, bullet.prevPos, bullet.pos)
    draw_sprite(SpriteID.BULLET, bulletRenderPos)
  }
}

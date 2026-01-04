package main

// #############################################################################
//                          Constants
// #############################################################################
MAX_BOMB_COUNT :: 100
BOMB_DROP_TIMER :: 1.0
BOMB_SPEED :: 1.5
ENEMY_STOP_TIMER :: 0.5

// #############################################################################
//                          Structs
// #############################################################################
Bomb :: struct
{
  prevPos :Vec2,
  pos :Vec2,
}

EnemyState :: enum
{
  MOVE_X,
  MOVE_Y,
  STOP
}

Enemy :: struct
{
  spriteID :SpriteID,
  state :EnemyState,
  size :Vec2,
  
  prevPos :Vec2,
  pos :Vec2,
  start_x_pos :f32,
  final_x_pos :f32,
  final_y_pos :f32,

  movement :Vec2,
  speed :f32,
  stop_timer :f32,

  bombs :Array(Bomb, MAX_BOMB_COUNT),
  bomb_timer :f32,
}

// #############################################################################
//                          Functions
// #############################################################################
enemy_init :: proc (enemy :^Enemy, pos: Vec2)
{
  enemy.spriteID = SpriteID.SHIP2
  enemy.state = EnemyState.STOP
  enemy.size = ivec2_f(SPRITES[enemy.spriteID].size)

  enemy.pos = Vec2{pos.x + 1.0, pos.y}
  enemy.prevPos = enemy.pos

  enemy.start_x_pos = pos.x
  enemy.final_x_pos = pos.x + WORLD_WIDTH / 2
  enemy.final_y_pos = pos.y

  enemy.movement.x = 1
  enemy.movement.y = 1
  enemy.speed = 1
  enemy.stop_timer = 0

  enemy.bomb_timer = 0.0
  enemy.bombs.count = 0
}

enemy_update :: proc(enemy :^Enemy, dt :f32)
{
  enemy.prevPos = enemy.pos
  
  // Update bomb Timer
  enemy.bomb_timer += dt

  // Handle States
  switch(enemy.state)
  {
  // Handle Move x
  case EnemyState.MOVE_X:
  {
    // Update Pos x
    enemy.pos.x += enemy.movement.x * enemy.speed

    if((i32(enemy.pos.x) - 16) % 32 == 0)
    {
      enemy.state = EnemyState.STOP
    }

    // Wall Collision
    if(enemy.pos.x <= enemy.start_x_pos)
    {
      enemy.movement.x = 1
      enemy.final_y_pos = enemy.pos.y + 16.0
      enemy.pos.x = enemy.start_x_pos

      enemy.state = EnemyState.STOP
    }
    else if(enemy.pos.x >= enemy.final_x_pos)
    {
      enemy.movement.x = -1
      enemy.final_y_pos = enemy.pos.y + 16.0
      enemy.pos.x = enemy.final_x_pos
      
      enemy.state = EnemyState.STOP
    }

    break
  }
  
  // Handle Move y
  case EnemyState.MOVE_Y:
  {
    // Update Pos y
    enemy.pos.y += enemy.movement.y * enemy.speed

    if(enemy.pos.y >= enemy.final_y_pos)
    {
      enemy.pos.y = enemy.final_y_pos
      enemy.state = EnemyState.STOP
    }

    break
  }
  
  // Handle STOP
  case EnemyState.STOP:
  {
    enemy.stop_timer += dt

    if(enemy.stop_timer >= ENEMY_STOP_TIMER)
    {
      enemy.stop_timer = 0
      
      if(enemy.pos.y < enemy.final_y_pos)
      {
        enemy.state = EnemyState.MOVE_Y
      }
      else
      {
        enemy.state = EnemyState.MOVE_X
      }
    }
    
    break
  }
  }

  // Drop Bombs
  if(enemy.bomb_timer >= BOMB_DROP_TIMER)
  {
    enemy.bomb_timer -= BOMB_DROP_TIMER
    if(enemy.bombs.count < MAX_BOMB_COUNT)
    {
      bomb :Bomb
      bomb.pos = Vec2{enemy.pos.x, enemy.pos.y + 10}
      bomb.prevPos = bomb.pos

      Array_add(&enemy.bombs, &bomb)
    }
  }

  // Update Bombs
  b :i32 = 0
  for b < enemy.bombs.count
  {
    bomb := &enemy.bombs.elements[b]

    bomb.prevPos = bomb.pos
    bomb.pos.y += BOMB_SPEED

    if(bomb.pos.y >= WORLD_HEIGHT + 50)
    {
      Array_swap_remove(&enemy.bombs, b)
    }
    else
    {
      b += 1
    }
  }
}

enemy_render :: proc(enemy :^Enemy, alpha :f32)
{
  enemyRenderPos := lerp_vec2(alpha, enemy.prevPos, enemy.pos)
  draw_sprite(enemy.spriteID, enemyRenderPos)

  // Draw Bombs
  for i :i32=0; i <enemy.bombs.count; i+=1
  {
    bomb := &enemy.bombs.elements[i]

    bombRenderPos := lerp_vec2(alpha, bomb.prevPos, bomb.pos)
    draw_sprite(SpriteID.BOMB, bombRenderPos)
  }
}

package main

// #############################################################################
//                           Constants
// #############################################################################
MAX_TRANSFORMS :: 1000

// #############################################################################
//                           Structs
// #############################################################################
Camera2D :: struct
{
  zoom :f32,
  pos :Vec2,
  dimensions :Vec2
}

Transform :: struct 
{
  atlasOffset :IVec2,
  spriteSize :IVec2,
  
  pos :Vec2,
  size :Vec2,

  tintColor :Vec4
}

RenderData :: struct
{
  // Cameras
  gameCamera :Camera2D,
  uiCamera :Camera2D,
  
  transforms :Array(Transform, MAX_TRANSFORMS),
  uiTransforms :Array(Transform, MAX_TRANSFORMS)
}

// #############################################################################
//                           Globals
// #############################################################################
renderData :RenderData

// #############################################################################
//                           Functions(Internal)
// #############################################################################
get_transform :: proc(spriteID :SpriteID, pos, size :Vec2, tintColor :Vec4) -> Transform
{
  sprite := SPRITES[spriteID]
  
  centerPos := Vec2{pos.x - size.x / 2, pos.y - size.y / 2}

  transform := Transform {
    atlasOffset = sprite.atlasOffset,
    spriteSize = sprite.size,
    pos = centerPos,
    size = size,
    tintColor = tintColor
  }

  return transform
}

get_transform_scale :: proc(spriteID :SpriteID, pos :Vec2, scale :f32, tintColor :Vec4) -> Transform
{
  sprite := SPRITES[spriteID]
  
  size := Vec2{f32(sprite.size.x) * scale, f32(sprite.size.y) * scale}
  
  centerPos := Vec2{pos.x - size.x / 2, pos.y - size.y / 2}

  transform := Transform {
    atlasOffset = sprite.atlasOffset,
    spriteSize = sprite.size,
    pos = centerPos,
    size = size,
    tintColor = tintColor
  }

  return transform
}

color_normal_opengl :: proc(c :Vec4) -> Vec4
{
  return Vec4{c.x / 255, c.y / 255, c.z / 255, c.w / 255}
}

// #############################################################################
//                           Functions(External)
// #############################################################################
// Game Rendering
draw_rect :: proc(pos, size: Vec2, color := Vec4{255, 255, 255, 255})
{
  transform := get_transform(SpriteID.QUAD, pos, size, color_normal_opengl(color))
  Array_add(&renderData.transforms, &transform) 
}

draw_sprite :: proc(spriteID :SpriteID, pos :Vec2, scale: f32 = 1.0, tintColor := Vec4{255, 255, 255, 255})
{
  transform := get_transform_scale(spriteID, pos, scale, color_normal_opengl(tintColor)) 
  Array_add(&renderData.transforms, &transform)
}

set_background :: proc(spriteID :SpriteID, scale :f32 = 1.0, tintColor := Vec4{255, 255, 255, 255})
{
  sprite := SPRITES[spriteID]

  size := Vec2{f32(sprite.size.x) * scale, f32(sprite.size.y) * scale}

  transform := Transform {
    atlasOffset = sprite.atlasOffset,
    spriteSize = sprite.size,
    pos = Vec2{0, 0},
    size = size,
    tintColor = color_normal_opengl(tintColor)
  }
  
  Array_add(&renderData.transforms, &transform)
}

// UI Rendering
draw_ui_button :: proc(button :^Button, tintColor := Vec4{255, 255, 255, 255})
{
  transform := get_transform(button.spriteID, button.rect.pos, button.rect.size, color_normal_opengl(tintColor))
  Array_add(&renderData.uiTransforms, &transform)
}

draw_ui_rect :: proc(pos, size: Vec2, color := Vec4{255, 255, 255, 255})
{
  transform := get_transform(SpriteID.QUAD, pos, size, color_normal_opengl(color))
  Array_add(&renderData.uiTransforms, &transform)
}

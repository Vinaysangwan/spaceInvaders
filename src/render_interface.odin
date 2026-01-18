package main

import "core:strings"
import "core:fmt"

// #############################################################################
//                           Constants
// #############################################################################
MAX_TRANSFORMS :: 1000
RENDERING_OPTION_FONT :: 0
RENDERING_OPTION_TEXTURE :: 1

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
  tintColor :Vec4,
  renderOption :i32,
  padding :[3]i32
}

Glyph :: struct
{
  offSet :Vec2,
  advance :Vec2,
  textureCoords :IVec2,
  size :IVec2
}

RenderData :: struct
{
  // Cameras
  gameCamera :Camera2D,
  uiCamera :Camera2D,
  
  fontHeight :i32,
  glyphs :[127]Glyph,
  baseFontSize :i32,
  
  // Transforms
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
    tintColor = tintColor,
    renderOption = RENDERING_OPTION_TEXTURE
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
    tintColor = tintColor,
    renderOption = RENDERING_OPTION_TEXTURE
  }

  return transform
}

color_normal_opengl :: proc(c :Vec4) -> Vec4
{
  return Vec4{c.x / 255, c.y / 255, c.z / 255, c.w / 255}
}

// #############################################################################
//                           Functions(Game Rendering)
// #############################################################################
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
    tintColor = color_normal_opengl(tintColor),
    renderOption = RENDERING_OPTION_TEXTURE
  }
  
  Array_add(&renderData.transforms, &transform)
}

// #############################################################################
//                           Functions(Ui Rendering)
// #############################################################################
draw_ui_rect :: proc(pos :Vec2, size :Vec2, tintColor := Vec4{255, 255, 255, 255})
{
  transform := get_transform(SpriteID.QUAD, pos, size, color_normal_opengl(tintColor))
  Array_add(&renderData.uiTransforms, &transform)
}

draw_ui_sprite :: proc(spriteID :SpriteID, pos :Vec2, scale :f32 = 1.0, tintColor := Vec4{255, 255, 255, 255})
{
  transform := get_transform_scale(spriteID, pos, scale, color_normal_opengl(tintColor))
  Array_add(&renderData.uiTransforms, &transform)
}

draw_ui_button :: proc(button :^Button, tintColor := Vec4{255, 255, 255, 255})
{
  transform := get_transform(button.spriteID, button.rect.pos, button.rect.size, color_normal_opengl(tintColor))
  Array_add(&renderData.uiTransforms, &transform)
}

draw_ui_text :: proc(text: string, pos: Vec2, fontSize: i32, color := Vec4{255, 255, 255, 255})
{
  pos := pos
  origin :Vec2 = pos
  tintColor := color_normal_opengl(color)

  for c in text
  {
    if(c == '\n')
    {
      pos.y += f32(renderData.fontHeight * fontSize)
      pos.x = origin.x
      continue
    }

    glyph := renderData.glyphs[c]
    
    transform := Transform{
      pos = Vec2{pos.x + glyph.offSet.x * f32(fontSize), pos.y - glyph.offSet.y * f32(fontSize)},
      atlasOffset = glyph.textureCoords,
      spriteSize = glyph.size,
      size = Vec2{f32(glyph.size.x * fontSize), f32(glyph.size.y * fontSize)},
      tintColor = tintColor,
      renderOption = RENDERING_OPTION_FONT
    }

    Array_add(&renderData.uiTransforms, &transform)
    pos.x += glyph.advance.x * f32(fontSize)
  }
}

draw_ui_format_text :: proc(pos :Vec2, fontSize :i32, color :Vec4, text :string, args :..any)
{
  strings.builder_reset(&ui_string_builder)
  text := fmt.sbprintf(&ui_string_builder, text, ..args)

  draw_ui_text(text, pos, fontSize, color)
}

draw_ui_FPS :: proc(pos :Vec2, fontSize: i32 = 2, color := Vec4{0, 255, 0, 255})
{
  draw_ui_format_text(pos, fontSize, color, "FPS: {}", FPS)
}

package main

import ma "vendor:miniaudio"

// #############################################################################
//                           Sprites
// #############################################################################
SpriteID :: enum
{
  QUAD,
  
  SHIP1,
  SHIP2,

  BULLET,
  BOMB,

  BUTTON_PLAY,
  BUTTON_QUIT,

  BG_MENU,
  BG_PLAY,

  COUNT
}

Sprite :: struct
{
  atlasOffset :IVec2,
  size :IVec2
}

SPRITES :[SpriteID.COUNT]Sprite = {
  SpriteID.QUAD = {atlasOffset = {0, 64}, size = {1, 1}},
  
  SpriteID.SHIP1 = {atlasOffset = {0, 0}, size = {32, 32}},
  SpriteID.SHIP2 = {atlasOffset = {32, 0}, size = {32, 32}},

  SpriteID.BULLET = {atlasOffset = {64, 0}, size = {2, 5}},
  SpriteID.BOMB = {atlasOffset = {80, 0}, size = {7, 7}},

  SpriteID.BUTTON_PLAY = {atlasOffset = {96, 0}, size = {128, 64}},
  SpriteID.BUTTON_QUIT = {atlasOffset = {256, 0}, size = {128, 64}},

  SpriteID.BG_MENU = {atlasOffset = {0, 96}, size = {320, 180}},
  SpriteID.BG_PLAY = {atlasOffset = {352, 96}, size = {320, 180}},
}

// #############################################################################
//                           Sounds
// #############################################################################
SoundID :: enum
{
  BG_MENU,
  
  COUNT
}

Sound :: struct
{
  sound :ma.sound,
  path :cstring
}

SOUNDS :[SoundID.COUNT]Sound = {
  SoundID.BG_MENU = {path = "assets/sounds/bg_music.mp3"}
}

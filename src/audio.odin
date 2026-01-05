package main

import ma "vendor:miniaudio"

// #############################################################################
//                           Constants
// #############################################################################

// #############################################################################
//                           Globals
// #############################################################################
audioEngine :ma.engine
audioEngineConfig :ma.engine_config

// #############################################################################
//                           Functions
// #############################################################################
audio_init :: proc()
{
  audioEngineConfig = ma.engine_config_init()

  if ma.engine_init(&audioEngineConfig, &audioEngine) != .SUCCESS
  {
    SM_ASSERT(false, "Failed to Init ")
  }

  ma.engine_start(&audioEngine)

  for i :i32 = 0; i < i32(SoundID.COUNT); i += 1
  {
    if(ma.sound_init_from_file(&audioEngine, SOUNDS[i].path, {.STREAM}, nil, nil, &SOUNDS[i].sound) != .SUCCESS)
    {
      SM_ASSERT(false, "Failed to load Sound: {}", SOUNDS[i].path)
    }
  }
}

audio_play :: proc(soundID :SoundID, looping :b32 = false)
{
  sound := &SOUNDS[soundID]
  
  ma.sound_set_looping(&sound.sound, looping)
  ma.sound_start(&sound.sound)
}

audio_stop :: proc(soundID :SoundID)
{
  ma.sound_stop(&SOUNDS[soundID].sound)
}

audio_cleanup :: proc()
{
  ma.engine_stop(&audioEngine)
  
  for i :i32 = 0; i < i32(SoundID.COUNT); i+= 1
  {
    ma.sound_uninit(&SOUNDS[i].sound)
  }

  ma.engine_uninit(&audioEngine)
}

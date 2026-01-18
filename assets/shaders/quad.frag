#version 430 core

// Defines
#define RENDERING_OPTION_FONT 0
#define RENDERING_OPTION_TEXTURE 1

// Inputs
layout (location = 0) in vec2 inTexCoords;
layout (location = 1) in vec4 inTintColor;
layout (location = 2) in flat int inRenderOption;

// Outputs
layout (location = 0) out vec4 outColor;

// Uniforms
layout (binding = 0) uniform sampler2D uTextureSampler;
layout (binding = 1) uniform sampler2D uFontSampler;

void main()
{
  if(inRenderOption == RENDERING_OPTION_FONT)
  {
    vec4 textureColor = texelFetch(uFontSampler, ivec2(inTexCoords), 0);

    if (textureColor.r == 0.0)
      discard;
    
    outColor = textureColor.r * inTintColor;
  }
  else
  {
    vec4 textureColor = texelFetch(uTextureSampler, ivec2(inTexCoords), 0);
    
    if (textureColor.a == 0.0)
      discard;
    
    outColor = textureColor * inTintColor;
  }
}

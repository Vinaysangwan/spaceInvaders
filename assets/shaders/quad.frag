#version 430 core

// Inputs
layout (location = 0) in vec2 inTexCoords;
layout (location = 1) in vec4 inTintColor;

// Outputs
layout (location = 0) out vec4 outColor;

// Uniforms
uniform sampler2D uTextureSampler;

void main()
{
  vec4 textureColor = texelFetch(uTextureSampler, ivec2(inTexCoords), 0);
  
  if (textureColor.a < 0.1)
    discard;
  
  outColor = textureColor * inTintColor;
}

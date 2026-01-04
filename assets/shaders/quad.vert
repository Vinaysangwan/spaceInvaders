#version 430 core

// Inputs

// Outputs
layout (location = 0) out vec2 outTexCoords;
layout (location = 1) out vec4 outTintColor;

// Uniforms
uniform mat4 uOrthoProjection;

// Structs
struct Transform 
{
  ivec2 atlasOffset;
  ivec2 spriteSize;
  vec2 pos;
  vec2 size;
  vec4 tintColor;
};

// Buffers
layout (std430, binding = 0) buffer bufTransformSBO
{
  Transform transforms[];
};

void main()
{
  Transform transform = transforms[gl_InstanceID];

  vec2 vertices[6] = 
  {
    // Left Top
    transform.pos,
    // Left Bottom
    vec2(transform.pos + vec2(0.0, transform.size.y)),
    // Right Top
    vec2(transform.pos + vec2(transform.size.x, 0.0)),

    // Right Top
    vec2(transform.pos + vec2(transform.size.x, 0.0)),
    // Left Bottom
    vec2(transform.pos + vec2(0.0, transform.size.y)),
    // Right Bottom
    transform.pos + transform.size
  };

  float left = transform.atlasOffset.x;
  float right = transform.atlasOffset.x + transform.spriteSize.x;
  float top = transform.atlasOffset.y;
  float bottom = transform.atlasOffset.y + transform.spriteSize.y;
  
  vec2 texCoords[6] = 
  {
    vec2(left, top),
    vec2(left, bottom),
    vec2(right, top),

    vec2(right, top),
    vec2(left, bottom),
    vec2(right, bottom)
  };

  vec2 vertexPos = vertices[gl_VertexID];
  gl_Position = uOrthoProjection * vec4(vertexPos, 0.0, 1.0);

  outTexCoords = texCoords[gl_VertexID];
  outTintColor = transform.tintColor;
}

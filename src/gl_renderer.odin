package main

import fs "vendor:fontstash"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "base:runtime"
import "vendor:stb/image"
import "core:c"

// #############################################################################
//                           Constants
// #############################################################################
TEXTURE_PATH :: "assets/textures/TEXTURE_ATLAS.png"

// #############################################################################
//                           Structs
// #############################################################################
GLContext :: struct
{
  programID :u32,
  textureID :u32,
  transformSBOID :u32,
  
  orthoProjectionLocation :i32
}

// #############################################################################
//                           Structs
// #############################################################################
glContext :GLContext

// #############################################################################
//                           Functions(Internal)
// #############################################################################
gl_error_callback :: proc "c" (source: u32, type: u32, id: u32, severity: u32, 
                               length: i32, message: cstring, userParam: rawptr)
{
  context = runtime.default_context()
  
  if (severity == gl.DEBUG_SEVERITY_LOW || 
      severity == gl.DEBUG_SEVERITY_MEDIUM ||
      severity == gl.DEBUG_SEVERITY_HIGH)
  {
    SM_ERROR("OPENGL_ERROR: %s", message)
  }
  else
  {
    SM_TRACE("%s", message)
  }
}

gl_get_ShaderID :: proc(shaderPath: string, type :u32) -> u32
{
  shaderID := gl.CreateShader(type)
  shaderSourceCode := read_file(shaderPath)

  shaderType :string
  if type == gl.VERTEX_SHADER
  {
    shaderType = "Vertex"
  }
  else if type == gl.FRAGMENT_SHADER
  {
    shaderType = "Fragment"
  }

  gl.ShaderSource(shaderID, 1, &shaderSourceCode, nil)
  gl.CompileShader(shaderID)

  success :i32 = 0;
  
  gl.GetShaderiv(shaderID, gl.COMPILE_STATUS, &success)
  if(success == 0)
  {
    infoLog := make([]u8, 1024)
    gl.GetShaderInfoLog(shaderID, 1024, nil, &infoLog[0])
    SM_ASSERT(false, "Failed to Compile [%s]: %s", shaderType, cast(cstring)&infoLog[0])
    return 0
  }
  
  return shaderID
}

// #############################################################################
//                           Functions(External)
// #############################################################################
gl_init :: proc() -> bool
{ 
  // Load OpenGL Functions
  gl.load_up_to(4, 3, glfw.gl_set_proc_address)

  // OpenGL Error Callback
  {
    gl.DebugMessageCallback(gl_error_callback, nil)
    gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
    gl.Enable(gl.DEBUG_OUTPUT)
  }

  // Shader Program
  {
    vertID := gl_get_ShaderID("assets/shaders/quad.vert", gl.VERTEX_SHADER)
    if(vertID == 0)
    {
      return false
    }
    
    fragID := gl_get_ShaderID("assets/shaders/quad.frag", gl.FRAGMENT_SHADER)
    if(fragID == 0)
    {
      return false
    }

    glContext.programID = gl.CreateProgram()
    gl.AttachShader(glContext.programID, vertID)
    gl.AttachShader(glContext.programID, fragID)
    gl.LinkProgram(glContext.programID)

    success :i32 = 0
    gl.GetProgramiv(glContext.programID, gl.LINK_STATUS, &success)
    if(success == 0)
    {
      infoLog := make([]u8, 1024)
      gl.GetProgramInfoLog(glContext.programID, 1024, nil, &infoLog[0])
      SM_ASSERT(false, "Failed to Link Shader Program[%d]: %s", glContext.programID, cast(cstring)&infoLog[0])
      return false
    }

    gl.DetachShader(glContext.programID, vertID)
    gl.DetachShader(glContext.programID, fragID)
    gl.DeleteShader(vertID)
    gl.DeleteShader(fragID)
  }

  // Load Texture
  {
    // Texture Data
    width, height, nChannels : c.int
    data := image.load(TEXTURE_PATH, &width, &height, &nChannels, 4);
    if(data == nil)
    {
      SM_ASSERT(false, "Failed to Open the Texture: %s", TEXTURE_PATH)
      return false
    }

    // Generate and Bind Texture
    gl.GenTextures(1, &glContext.textureID)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, glContext.textureID)

    // Texture Parameters
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.SRGB8_ALPHA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
    image.image_free(data)
  }

  // Transform Storage Buffer
  {
    gl.GenBuffers(1, &glContext.transformSBOID)
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, glContext.transformSBOID)
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(Transform) * MAX_TRANSFORMS, &renderData.transforms.elements[0], gl.STATIC_DRAW)
  }

  // Uniforms
  {
    glContext.orthoProjectionLocation = gl.GetUniformLocation(glContext.programID, "uOrthoProjection")
  }
  
  // VAO
  VAO :u32
  gl.GenVertexArrays(1, &VAO)
  gl.BindVertexArray(VAO)

  // glEnables
  gl.Enable(gl.FRAMEBUFFER_SRGB)

  // Use Shader Program
  gl.UseProgram(glContext.programID)
  
  return true
}

gl_render :: proc()
{
  gl.ClearColor(0.2, 0.3, 0.3, 1.0)
  gl.Clear(gl.COLOR_BUFFER_BIT)

  // Game Layer
  {
    // Camera
    camera := renderData.gameCamera

    orthoMatrix := orthogonal_matrix(camera.pos.x - camera.dimensions.x / 2.0, camera.pos.x + camera.dimensions.x / 2.0,
                                         camera.pos.y - camera.dimensions.y / 2.0, camera.pos.y + camera.dimensions.y / 2.0)
    
    gl.UniformMatrix4fv(glContext.orthoProjectionLocation, 1, gl.FALSE, &orthoMatrix.elements[0])
  
    // Transform
    gl.BufferSubData(gl.SHADER_STORAGE_BUFFER, 0, int(size_of(Transform) * renderData.transforms.count), &renderData.transforms.elements[0])

    gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, renderData.transforms.count)

    renderData.transforms.count = 0
  }

  // UI Layer
  {
    // Camera
    camera := renderData.uiCamera

    orthoMatrix := orthogonal_matrix(camera.pos.x - camera.dimensions.x / 2.0, camera.pos.x + camera.dimensions.x / 2.0,
                                         camera.pos.y - camera.dimensions.y / 2.0, camera.pos.y + camera.dimensions.y / 2.0)
    
    gl.UniformMatrix4fv(glContext.orthoProjectionLocation, 1, gl.FALSE, &orthoMatrix.elements[0])
    
    // Transform
    gl.BufferSubData(gl.SHADER_STORAGE_BUFFER, 0, int(size_of(Transform) * renderData.uiTransforms.count), &renderData.uiTransforms.elements[0])

    gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, renderData.uiTransforms.count)

    renderData.uiTransforms.count = 0
  }
}

gl_cleanup :: proc()
{
  gl.BindVertexArray(0)

  gl.UseProgram(0)
  gl.DeleteProgram(glContext.programID)
}

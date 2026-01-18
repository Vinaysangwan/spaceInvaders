package main

import "core:mem"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "vendor:stb/image"
import tt "vendor:stb/truetype"
import "base:runtime"
import "core:c"
import "core:os"

// #############################################################################
//                           Constants
// #############################################################################
TEXTURE_PATH :: "assets/textures/TEXTURE_ATLAS.png"
FONT_ATLAS_SIZE :: 512
FIRST_CHAR :: 32
LAST_CHAR :: 127
PADDING :: 2

// #############################################################################
//                           Structs
// #############################################################################
GLContext :: struct
{
  programID :u32,
  textureID :u32,
  transformSBOID :u32,
  fontAtlashID :u32,
  
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
    logLength :i32 = 0
    gl.GetShaderInfoLog(shaderID, 1024, &logLength, &infoLog[0])
    
    if (logLength < i32(len(infoLog)))
    {
      infoLog[logLength] = 0     
    }
    else
    {
      infoLog[len(infoLog) - 1] = 0
    }
    
    SM_ASSERT(false, "Failed to Compile [%s]: %s", shaderType, cast(cstring)(&infoLog[0]))
    return 0
  }
  
  return shaderID
}

load_font :: proc(filePath: string, fontSize: i32)
{
  // --------------------------------------------------
  // Load TTF
  // --------------------------------------------------
  ttfData, ok := os.read_entire_file(filePath)
  SM_ASSERT(ok, "Failed to open font: {}", filePath)

  fontInfo: tt.fontinfo
  SM_ASSERT(bool(tt.InitFont(&fontInfo, &ttfData[0], 0)), "Failed to init stb font")

  scale := tt.ScaleForPixelHeight(&fontInfo, f32(fontSize))

  // Font metrics (equivalent to FreeType size->metrics)
  ascent, descent, lineGap: i32
  tt.GetFontVMetrics(&fontInfo, &ascent, &descent, &lineGap)

  renderData.fontHeight = max(renderData.fontHeight, i32(f32(ascent - descent) * scale))

  renderData.baseFontSize = fontSize

  // --------------------------------------------------
  // Atlas buffer
  // --------------------------------------------------
  atlas := make([]u8, FONT_ATLAS_SIZE * FONT_ATLAS_SIZE)
  mem.set(&atlas[0], 0, len(atlas))

  row: i32 = 0
  col: i32 = PADDING

  // --------------------------------------------------
  // Glyph loop (ASCII 32–126)
  // --------------------------------------------------
  for ch: rune = FIRST_CHAR; ch < LAST_CHAR; ch += 1
  {
    glyphIndex := tt.FindGlyphIndex(&fontInfo, ch)

    // Advance (FreeType: advance.x >> 6)
    advance, lsb: i32
    tt.GetGlyphHMetrics(&fontInfo, glyphIndex, &advance, &lsb)

    // Bitmap box (relative to baseline)
    x0, y0, x1, y1: i32
    tt.GetGlyphBitmapBox(
      &fontInfo,
      glyphIndex,
      scale, scale,
      &x0, &y0, &x1, &y1,
    )

    width  := x1 - x0
    height := y1 - y0

    if col + width + PADDING >= FONT_ATLAS_SIZE 
    {
      col = PADDING
      row += fontSize
    }

    // Rasterize glyph bitmap into atlas
    tt.MakeGlyphBitmap(
      &fontInfo,
      &atlas[row * FONT_ATLAS_SIZE + col],
      width,
      height,
      FONT_ATLAS_SIZE,
      scale, scale,
      glyphIndex,
    )

    // --------------------------------------------------
    // Glyph data (matches FreeType semantics)
    // --------------------------------------------------
    g := &renderData.glyphs[ch]

    g.textureCoords = IVec2{col, row}
    g.size          = IVec2{width, height}

    g.advance = Vec2{f32(advance) * scale, 0}

    // IMPORTANT:
    // FreeType bitmap_top  == ascent above baseline
    // stb y0 is NEGATIVE above baseline → invert sign
    g.offSet = Vec2{f32(x0), f32(-y0)}

    col += width + PADDING
  }

  // --------------------------------------------------
  // Upload OpenGL texture (same as C++)
  // --------------------------------------------------
  gl.GenTextures(1, &glContext.fontAtlashID)
  gl.ActiveTexture(gl.TEXTURE1)
  gl.BindTexture(gl.TEXTURE_2D, glContext.fontAtlashID)

  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.R8, FONT_ATLAS_SIZE, FONT_ATLAS_SIZE, 0, gl.RED, gl.UNSIGNED_BYTE, &atlas[0])

  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
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

  // Load Fonts
  {
    load_font("assets/fonts/AtariClassic-gry3.ttf", 8)
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

package main

import "core:os"
import "core:fmt"
import "base:runtime"

// #############################################################################
//                           Logger
// #############################################################################
TextColor :: enum
{  
  BLACK,
  RED,
  GREEN,
  YELLOW,
  BLUE,
  MAGENTA,
  CYAN,
  WHITE,
  BRIGHT_BLACK,
  BRIGHT_RED,
  BRIGHT_GREEN,
  BRIGHT_YELLOW,
  BRIGHT_BLUE,
  BRIGHT_MAGENTA,
  BRIGHT_CYAN,
  BRIGHT_WHITE,

  COUNT
}

TEXT_COLOR_TABLE := [TextColor.COUNT]string {
	TextColor.BLACK          = "\x1b[30m",
	TextColor.RED            = "\x1b[31m",
	TextColor.GREEN          = "\x1b[32m",
	TextColor.YELLOW         = "\x1b[33m",
	TextColor.BLUE           = "\x1b[34m",
	TextColor.MAGENTA        = "\x1b[35m",
	TextColor.CYAN           = "\x1b[36m",
	TextColor.WHITE          = "\x1b[37m",

	TextColor.BRIGHT_BLACK   = "\x1b[90m",
	TextColor.BRIGHT_RED     = "\x1b[91m",
	TextColor.BRIGHT_GREEN   = "\x1b[92m",
	TextColor.BRIGHT_YELLOW  = "\x1b[93m",
	TextColor.BRIGHT_BLUE    = "\x1b[94m",
	TextColor.BRIGHT_MAGENTA = "\x1b[95m",
	TextColor.BRIGHT_CYAN    = "\x1b[96m",
	TextColor.BRIGHT_WHITE   = "\x1b[97m"
}

_log :: proc(prefix, msg :string, color :TextColor, args :..any)
{
  colorCode := TEXT_COLOR_TABLE[color]
  reset := "\x1b[0m"

  fmt.print(colorCode)
  fmt.print(prefix)
  fmt.printf(msg, ..args)
  fmt.printf(reset)
  fmt.println("")
}

SM_TRACE :: proc(msg: string, args :..any)
{
  _log("TRACE: ", msg, TextColor.GREEN, ..args)
}

SM_WARN :: proc(msg: string, args :..any)
{
  _log("WARN: ", msg, TextColor.YELLOW, ..args)
}

SM_ERROR :: proc(msg: string, args :..any)
{
  _log("ERROR: ", msg, TextColor.RED, ..args)
}

SM_ASSERT :: proc(x :bool, msg :string, args :..any)
{
  if(!(x))
  {
    SM_ERROR(msg, ..args)
    runtime.debug_trap()
  }
}

// #############################################################################
//                           FILE I/O
// #############################################################################
read_file :: proc(filePath :string) -> cstring
{
  data, ok := os.read_entire_file(filePath)

  if(!ok)
  {
    SM_ERROR("Failed to open the file: %s", filePath)
    return nil
  }

  buf := make([]u8, len(data) + 1)
  copy(buf, data)
  buf[len(data)] = 0

  return cast(cstring) &buf[0]
}

// #############################################################################
//                           Array
// #############################################################################
Array :: struct(T :typeid, N :i32)
{
  elements :[N]T,
  count :i32
}

Array_add :: proc(a :^Array($T, $N), value :^T)
{
  SM_ASSERT(a.count < N, "Array is FULL!")

  a.elements[a.count] = value^
  a.count += 1
}

Array_isFull :: proc(a :^Array($T, $N)) -> bool
{
  return a.count == N
}

Array_clear :: proc(a :^Array($T, $N))
{
  a.count = 0
}

Array_swap_remove :: proc(a :^Array($T, $N), idx :i32)
{
  a.count -= 1
  a.elements[idx] = a.elements[a.count]
}

Array_get :: proc(a :^Array($T, $N), idx :i32) -> T
{
  SM_ASSERT(idx < N && idx >=0, "Idx is out of bounds!")
  return a.elements[idx]
}

Array_get_value :: proc(a :^Array($T, $N), idx :i32) -> ^T
{
  SM_ASSERT(idx < N && idx >=0, "Idx is out of bounds!")
  return a.elements[idx]
}

// #############################################################################
//                           Vectors
// #############################################################################
IVec2 :: struct 
{
  x :i32,
  y :i32
}

Vec2 :: struct
{
  x :f32,
  y :f32
}

ivec2_f :: proc(vec :IVec2) -> Vec2
{
  return Vec2{f32(vec.x), f32(vec.y)}
}

vec2_i :: proc(vec :Vec2) -> IVec2
{
  return IVec2{i32(vec.x), i32(vec.y)}
}

Vec4 :: struct
{     
  x :f32,
  y :f32,
  z :f32,
  w :f32
}

// #############################################################################
//                           Matrix
// #############################################################################
Mat4f :: struct
{
  elements :[16]f32
}

orthogonal_matrix :: proc(left, right, top, bottom :f32) -> Mat4f
{
  result :Mat4f

  result.elements[0 + 3 * 4] = -(right + left) / (right - left)
  result.elements[1 + 3 * 4] = (top + bottom) / (top - bottom)
  result.elements[2 + 3 * 4] = 0.0

  result.elements[0 + 0 * 4] = 2.0 / (right - left)
  result.elements[1 + 1 * 4] = 2.0 / (top - bottom)
  result.elements[2 + 2 * 4] = 1.0
  result.elements[3 + 3 * 4] = 1.0
  
  return result
}

// #############################################################################
//                           Rects
// #############################################################################
Rect :: struct
{
  pos :Vec2,
  size :Vec2
}

// #############################################################################
//                           Maths
// #############################################################################
lerp :: proc(alpha, prev, current :f32) -> f32
{
  return (prev + (current - prev) * alpha)
}

lerp_vec2 :: proc(alpha :f32, prevVec, currentVec :Vec2) -> Vec2
{
  return Vec2{
    x = lerp(alpha, prevVec.x, currentVec.x),
    y = lerp(alpha, prevVec.y, currentVec.y)
  }
}

// #############################################################################
//                           Collisions
// #############################################################################
Collision_Rect_Point :: proc(rect :^Rect, point :Vec2) -> bool
{
  if(point.x > rect.pos.x - rect.size.x / 2 && point.x < rect.pos.x + rect.size.x / 2 &&
     point.y > rect.pos.y - rect.size.y / 2 &&  point.y < rect.pos.y + rect.size.y / 2)
  {
    return true
  }
  else
  {
    return false
  }
}

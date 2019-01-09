import
  nimgl/[opengl, stb/image],
  strformat,
  os

# TODO(Dustin): Make a new issue for the nimgl library for
# not including these enums
const STBI_default = 0
const STBI_gray_alpha = 2
const STBI_rgb = 3
const STBI_rgb_alpha = 4

type
  Image* = object
    id: GLuint
    width, height: int
    format: Format

  Filter* = enum
    Linear,
    Nearest

  Format* = enum
    fmtGray = 1,
    fmtGrayAlpha = 2,
    fmtRgb = 3,
    fmtRgba = 4

  Region* = object
    x, y, width, height: int

proc newRegion* (x, y, width, height: int): auto=
  result = Region(x: x, y: y, width: width, height: height)

template width* (self: Image): auto = self.width
template height* (self: Image): auto = self.height
template id* (self: Image): auto = self.id

proc loadImage* (path: string, filter=Nearest): Image=
  result = Image(id: 0, width: 0, height: 0, format: fmtRgba)

  if not fileExists(path):
    echo &"loadImage::Warning:: Cannot find image: {path}"
    return

  # NOTE(Dustin): Probably dont need to do this on each load, 
  # but I'm guessing its cheap
  stbiSetFlipVerticallyOnLoad true

  var width, height, channels = 0'i32

  var format = 0
  var data = stbiLoad(
    path.cstring,
    addr width,
    addr height,
    addr channels,
    STBI_default)

  # TODO(Dustin): Better error handling
  if data == nil:
    echo "Failed to load image: ", path
    return

  result.width = width
  result.height = height
  result.format = (Format)channels

  glGenTextures(1, addr result.id)
  glBindTexture(GL_TEXTURE_2D, result.id)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
    case filter:
    of Nearest: (GLint)GL_NEAREST
    of Linear:  (GLint)GL_LINEAR)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
    case filter:
    of Nearest: (GLint)GL_NEAREST
    of Linear:  (GLint)GL_LINEAR)

  let lvl: GLint  = 0
  let fmt         = GLint(GL_RGB)
  let w           = result.width.int32
  let h           = result.height.int32

  case result.format:
  # of Format.fmtGray:
  # of Foramt.fmtGrayAlpha:
  of Format.fmtRGB:
    glTexImage2D(
      GL_TEXTURE_2D,
      lvl,
      GL_RGB.ord,
      w,
      h,
      0,
      GL_RGB.ord,
      GL_UNSIGNED_BYTE,
      data)
  of Format.fmtRGBA:
    glTexImage2D(
      GL_TEXTURE_2D,
      lvl,
      GL_RGBA.ord,
      w,
      h,
      0,
      GL_RGBA.ord,
      GL_UNSIGNED_BYTE,
      data)
  else: discard

  glBindTexture(GL_TEXTURE_2D, 0)

proc bindImage* (image: Image)=
  glBindTexture(GL_TEXTURE_2D, image.id)

proc unBindImage* (image: Image)=
  glBindTexture(GL_TEXTURE_2D, 0)

template useImage* (image: Image, body: untyped)=
  image.bindImage()
  body
  image.unBindImage()

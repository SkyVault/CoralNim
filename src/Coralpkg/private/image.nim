import
  opengl,
  strformat,
  os,
  stb_image/read as stbi

type
  Image* = object
    id: GLuint
    width, height: int
    format: Format

  Filter* = enum
    Linear,
    Nearest

  Format* = enum
    Rgb,
    Rgba

  Region* = object
    x, y, width, height: int

proc newRegion* (x, y, width, height: int): auto=
  result = Region(x: x, y: y, width: width, height: height)

template width* (self: Image): auto = self.width
template height* (self: Image): auto = self.height

proc loadImage* (path: string, filter=Nearest): Image=
  result = Image(id: 0, width: 0, height: 0, format: Rgba)

  if not fileExists(path):
    echo &"loadImage::Warning:: Cannot find image: {path}"
    return

  # NOTE(Dustin): Probably dont need to do this on each load, 
  # but I'm guessing its cheap
  stbi.setFlipVerticallyOnLoad true

  try:
    var format = 0
    var data = stbi.load(
      path,
      result.width,
      result.height,
      format,
      stbi.Default)

    glGenTextures(1, addr result.id)
    glBindTexture(GL_TEXTURE_2D, result.id)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      case filter:
      of Nearest: GL_NEAREST
      of Linear: GL_LINEAR)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
      case filter:
      of Nearest: GL_NEAREST
      of Linear: GL_LINEAR)

    let lvl: GLint  = 0
    let fmt         = GLint(GL_RGB)
    let w           = GLsizei(result.width)
    let h           = GLsizei(result.height)

    case format:
    of 3:
      glTexImage2D(GL_TEXTURE_2D,lvl, fmt, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, addr data[0])
      result.format = Rgb
    of 4:
      glTexImage2D(GL_TEXTURE_2D,lvl, GLint(GL_RGBA), w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, addr data[0])
      result.format = Rgba
    else: discard

    glBindTexture(GL_TEXTURE_2D, 0)
  except STBIException:
    echo failureReason()

proc bindImage* (image: Image)=
  glBindTexture(GL_TEXTURE_2D, image.id)

proc unBindImage* (image: Image)=
  glBindTexture(GL_TEXTURE_2D, 0)

template useImage* (image: Image, body: untyped)=
  image.bindImage()
  body
  image.unBindImage()

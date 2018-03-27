## This contains a nim like wrapper over OpenGL, also some useful datatypes
## and procedures to make working with graphics a breeze

import
    gameMath,
    game,
    random,
    opengl,
    glu,
    strutils,
    glfw,
    os,
    math,
    stb_image/read as stbi,
    tables

type
    BufferType* = enum
        VERTEX_BUFFER,
        ELEMENT_BUFFER

    ShaderType* = enum
        FRAGMENT_SHADER,
        VERTEX_SHADER,
        GEOMETRY_SHADER

    Color* = ref object
        ## This is the main color structure.
        r* , g* , b* , a* : float32
        
    Region* = ref object of RootObj
        ## Region defines the portion of a texture to draw
        x* , y* , w* , h* : int

    Rect* = ref object of RootObj
        ## Defines a float rect
        x*, y* , w* , h* : float

    Image* = ref object
        id: GLuint
        width* , height* , channels* : int

    Camera2D* = ref object
        position*   : V2
        offset*     : V2
        zoom*       : float32
        rotation*   : float32

    Glyph* = ref object
      id*: uint
      region*: Region
      yoffset*, xoffset*, xadvance*: float
    
    SpriteFont* = ref object
      glyphs*: TableRef[uint, Glyph]
      image*: Image

proc `$`* (r: Region): string

proc newRegion* (x, y, w, h: int): Region=
    Region(
        x: x, y: y, w: w, h: h
    )

# Color stuff
proc newColor*(r: float32 = 1, g: float32 = 1, b: float32 = 1, a: float32 = 1): Color=
    Color( r: r, g: g, b: b, a: a )

proc lerp* (a: Color, b: Color, t: float): Color=
    result = newColor(
        lerp(a.r, b.r, t),
        lerp(a.g, b.g, t),
        lerp(a.b, b.b, t),
        lerp(a.a, b.a, t)
    )

proc lerpPercent* (a: Color, b: Color, t: float): Color=
    result = newColor(
        lerpPercent(a.r, b.r, t),
        lerpPercent(a.g, b.g, t),
        lerpPercent(a.b, b.b, t),
        lerpPercent(a.a, b.a, t)
    )

proc length* (c: Color): float=
    return sqrt(
        (c.r * c.r) +
        (c.g * c.g) +
        (c.a * c.a)
    )

## Defines a custom pallet of colors
template Red*                  ():untyped =newColor(1, 0, 0)
template Green*                ():untyped =newColor(0, 1, 0)
template Blue*                 ():untyped =newColor(0, 0, 1)
template White*                ():untyped =newColor(1, 1, 1)
template Black*                ():untyped =newColor(0, 0, 0)
template DarkGray*             ():untyped =newColor(0.2, 0.2, 0.2)
template LightGray*            ():untyped =newColor(0.8, 0.8, 0.8)
template Gray*                 ():untyped =newColor(0.5, 0.5, 0.5)
template Transperent*          ():untyped =newColor(1, 1, 1, 0)
template TransperentBlack*     ():untyped =newColor(0, 0, 0, 0)

## Pico 8 Color palette
template P8Black*      ():untyped = newColor(0, 0, 0, 1)
template P8DarkBlue*   ():untyped = newColor(29.0 / 255.0, 43.0 / 255.0, 83.0 / 255.0)
template P8DarkPurple* ():untyped = newColor(126.0 / 255.0, 37.0 / 255.0, 83.0 / 255.0)
template P8DarkGreen*  ():untyped = newColor(0.0, 135.0 / 255.0, 81.0 / 255.0)
template P8Brown*      ():untyped = newColor(171.0 / 255.0, 82.0 / 255.0, 54.0 / 255.0)
template P8DarkGray*   ():untyped = newColor(95.0 / 255.0, 87.0 / 255.0, 79.0 / 255.0)
template P8LightGray*  ():untyped = newColor(194.0 / 255.0, 195.0 / 255.0, 199.0 / 255.0)
template P8White*      ():untyped = newColor(1.0, 241.0 / 255.0, 232.0 / 255.0)
template P8Red*        ():untyped = newColor(1.0, 0.0, 77.0 / 255.0)
template P8Orange*     ():untyped = newColor(1.0, 163.0 / 255.0, 0.0) 
template P8Yellow*     ():untyped = newColor(1.0, 236.0 / 255.0, 39.0 / 255.0)
template P8Green*      ():untyped = newColor(0.0, 228.0 / 255.0, 54.0 / 255.0)
template P8Blue*       ():untyped = newColor(41.0 / 255.0, 173.0 / 255.0, 1.0)
template P8Indigo*     ():untyped = newColor(131.0 / 255.0, 118.0 / 255.0, 156.0 / 255.0)
template P8Pink*       ():untyped = newColor(1.0, 119.0 / 255.0, 168.0 / 255.0)
template P8Peach*      ():untyped = newColor(1.0, 204.0 / 255.0, 170.0 / 255.0)

# TODO: lets make it so that the user can choose to clear the depth buffer or color buffer or depth stencel.
proc clearScreen* (c: Color)=
    glClearColor(c.r, c.g, c.b, c.a)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc toColor* (c: (float32,float32,float32,float32)):Color=
    ## Converts a 4 unit tuple of floats to a Color. 
    return newColor(c[0], c[1], c[2], c[3])

proc toColor* (c: V3): Color    = return newColor(c.x, c.y, c.z, 1)
proc toV3* (c: Color): V3       = newV3(c.r, c.g, c.b)

proc hexColorToFloatColor* (hex: string): (float32, float32, float32, float32)=
    var
        r = 0.0'f32
        g = 0.0'f32
        b = 0.0'f32
        a = 1.0'f32

    var nhex = ""
    if len(hex) > 1:
        if hex[0] == '#': nhex = hex[1..<len(hex)]
    else:
        echo "hexColorToFloatColor::Error:: invalid color string: ", hex
        return (r, g, b, a)

    let nlen = len(nhex)
    case nlen:
    of 6:
        r = (float32(parseHexInt(nhex[0..1])) / 255.0)
        g = (float32(parseHexInt(nhex[2..3])) / 255.0)
        b = (float32(parseHexInt(nhex[4..5])) / 255.0)
    of 8:
        r = (float32(parseHexInt(nhex[0..1])) / 255.0)
        g = (float32(parseHexInt(nhex[2..3])) / 255.0)
        b = (float32(parseHexInt(nhex[4..5])) / 255.0)
        a = (float32(parseHexInt(nhex[6..7])) / 255.0)
    else:
        echo "hexColorToFloatColor::Error:: invalid color string: ", hex
        return (r,g,b,a)
    return(r, g, b, a)

proc hexColorToColor* (hex: string): Color=
    return toColor(hexColorToFloatColor(hex))

# Opengl Wrapper stuff
proc getGLenumArrayType(t: BufferType): GLenum=
    result = 
        case(t):
        of VERTEX_BUFFER: GL_ARRAY_BUFFER
        of ELEMENT_BUFFER: GL_ELEMENT_ARRAY_BUFFER 
        else: GL_ARRAY_BUFFER

proc newVao* (shouldBind = false): GLuint=
    glGenVertexArrays(1, addr result)
    if shouldBind: glBindVertexArray(result)

proc newVbo* (btype: BufferType, dimensions: uint32, attrib: uint32, data: var seq[float32], dynamic = false): GLuint=
    let theType = getGLenumArrayType btype
    
    glGenBuffers(1, addr result)
    glBindBuffer(theType, result)
    glBufferData(
        theType,
        cast[GLsizeiptr](sizeof(float32) * data.len),
        addr data[0],
        if dynamic: GL_DYNAMIC_DRAW
        else: GL_STATIC_DRAW)
    
    glEnableVertexAttribArray(GLuint(attrib))
    glVertexAttribPointer(
        (GLuint)attrib,
        (GLint)dimensions,
        cGL_FLOAT,
        GL_FALSE,
        GLsizei(0),
        nil
    )
    glBindBuffer(theType, 0)

proc drawArrays* (vao: GLuint, numVertices: int)=
        glBindVertexArray(vao)
        glDrawArrays(GL_TRIANGLES, 0, (GLsizei)numVertices)
        glBindVertexArray(0)

## Shader code
proc loadShader* (stype: ShaderType, code: string): GLuint=
    var theType: GLenum
    if stype == VERTEX_SHADER: theType = GL_VERTEX_SHADER
    if stype == FRAGMENT_SHADER: theType = GL_FRAGMENT_SHADER
    
    result = glCreateShader(theType)
    let cstra = allocCStringArray([code])
    glShaderSource(result, 1, cstra, nil)
    glCompileShader(result)

    var
        res: GLint = 0
        log_len: GLint = 0

    glGetShaderiv(result, GL_COMPILE_STATUS, addr res)
    glGetShaderiv(result, GL_INFO_LOG_LENGTH, addr log_len)

    if log_len > 0:
        var log: cstring = cast[cstring](alloc(log_len + 1))
        glGetShaderInfoLog(
            result,
            (GLsizei)log_len,
            nil,
            log
            )
        echo if theType == GL_VERTEX_SHADER: "VERTEX::"
             else: "FRAGMENT::", log
        dealloc(log)

proc newProgram* (v: GLuint, f: GLuint): GLuint=
    result = glCreateProgram()
    glAttachShader(result, v)
    glAttachShader(result, f)
    glLinkProgram(result)

    var
        res: GLint = 0
        log_len: GLint = 0

    glGetProgramiv(result, GL_LINK_STATUS, addr res)
    glGetProgramiv(result, GL_INFO_LOG_LENGTH, addr log_len)
    if log_len > 0:
        var log: cstring = cast[cstring](alloc(log_len + 1))
        glGetProgramInfoLog(result, (GLsizei)log_len, nil, log)
        echo "PROGRAM::",log
        dealloc(log) # might not need to with garbage collection

proc bindProgram* (p: GLuint)   = glUseProgram(p)
proc unBindProgram* ()          = glUseProgram(0)

proc setUniform* (p: GLuint, loc: GLint, f: float32)= glUniform1f(loc, f)
proc setUniform* (p: GLuint, loc: GLint, v: V2)= glUniform2f(loc, v.x, v.y)
proc setUniform* (p: GLuint, loc: GLint, v: V3)= glUniform3f(loc, v.x, v.y, v.z)
proc setUniform* (p: GLuint, loc: GLint, v: V3, f: float32)= glUniform4f(loc, v.x, v.y, v.z, f)
proc setUniform* (p: GLuint, loc: GLint, v: int32)= glUniform1i(loc, v)
proc setUniform* (p: GLuint, loc: GLint, m: var M4)=
    glUniformMatrix4fv(loc, 1, GL_TRUE, addr m.m[0])

proc getLocation* (p: GLuint, id: cstring): GLint=
    result = glGetUniformLocation(p, id)
    if result == -1:
        echo "nGetLocation:: cannot find uniform " & $id

proc loadImage* (path: string, filter: GLint = GL_LINEAR): Image=
    result = Image(id: 0, width: 0, height: 0)

    stbi.setFlipVerticallyOnLoad true
    var data = stbi.load(path, result.width, result.height, result.channels, stbi.Default)

    glGenTextures(1, addr result.id)
    glBindTexture(GL_TEXTURE_2D, result.id)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter)

    let lvl: GLint  = 0
    let fmt         = GLint(GL_RGB)
    let w           = GLsizei(result.width)
    let h           = GLsizei(result.height)

    case result.channels:
    of 3: glTexImage2D(GL_TEXTURE_2D,lvl, fmt, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, addr data[0])
    of 4: glTexImage2D(GL_TEXTURE_2D,lvl, GLint(GL_RGBA), w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, addr data[0])
    else: discard
    glBindTexture(GL_TEXTURE_2D, 0)

proc getID* (img: Image): GLuint= return img.id

proc bindImage* (img: Image)= glBindTexture(GL_TEXTURE_2D, img.id)
proc unBindImage* ()= glBindTexture(GL_TEXTURE_2D, 0)

proc loadSpriteFont* (path: string, image_path: string): SpriteFont=
  result = SpriteFont(
    glyphs: newTable[uint, Glyph](),
    image: loadImage(image_path)
  )

  for line in lines path:
    var tokens = newSeq[string]()
    let seps = {' ', '='}
    for token in tokenize(line, seps):
      tokens.add token.token

    if len(tokens) == 0: continue
    if tokens[0] == "char":
      let id = (uint)(parseInt(tokens[4]))
      let theGlyph = Glyph(
        id: id,
        region: newRegion(
          parseInt(tokens[8]),
          parseInt(tokens[12]),
          parseInt(tokens[16]),
          parseInt(tokens[20])
        ),
        xoffset: parseFloat(tokens[24]),
        yoffset: parseFloat(tokens[28]),
        xadvance: parseFloat(tokens[32])
      )

      result.glyphs.add(id, theGlyph)

proc measure* (font: SpriteFont, scale: float, str: string): V2=
  var xlen = 0.0
  var ylen = 0.0
  var yoff = 0.0
  for c in str:
    if c == ' ':
      xlen += font.glyphs[uint(' ')].xadvance * scale
      continue

    if c in Newlines:
      yoff += (float)(font.glyphs[uint('A')].region.h) * scale
      continue

    let id = uint(c)
    let glyph = font.glyphs[id]
    let height = ((float32)(glyph.region.h) + glyph.yoffset) * scale

    if height > ylen:
      ylen = height

    xlen += ((float32)(glyph.region.w) + glyph.xoffset) * scale
  return newV2((float32)xlen, (float32)ylen + yoff)

## Camera 2D
proc view* (camera: Camera2D): M2=
    return translation(camera.position.x, camera.position.y)

# Printing the data types
proc `$`* (r: Region): string=
    result = "nRegion {\n"
    result &= "   x: " & $r.x & "\n"
    result &= "   y: " & $r.y & "\n"
    result &= "   w: " & $r.w & "\n"
    result &= "   h: " & $r.h & "\n}\n"


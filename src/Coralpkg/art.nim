# Main Renderer for the Coral frame work
import
  sequtils,
  platform,
  opengl,
  math,
  tables,
  cgl,
  maths

type
  Vertex* = ref object
    position*: (float, float)

  Renderer* = ref object
    rectBuffers: (GLuint, GLuint)

  Drawable = object
    region: Region
    body: (float, float, float, float) # x y w h
    transform: (float, float) # rot depth


include private/shaders

proc drawLine* (x1, y1, x2, y2: int | float, thickness=4.0)
proc drawCircle* (x, y, radius: int | float, resolution=360)
proc drawRect* (x, y, width, height: int | float, rotation=0.0, offsetX, offsetY=0.0)
proc drawLineRect* (x, y, width, height: int | float, rotation=0.0, thickness=4.0)

proc drawImage* (image: Image, x, y: int | float = 0.0)
proc drawImage* (image: Image, x, y, width, height: int | float, rot=0.0, depth=0.0)

var ortho_projection: Mat4
var rect_vao, rect_vbo: GLuint

var prim_vao, prim_vbo, prim_cbo: GLuint

var program: GLuint
var primitive_program: GLuint

var color = (1.0, 1.0, 1.0, 1.0)

var RECT_VERTICES = @[
  0.0'f32, 1.0,
  1.0,     0.0,
  0.0,     0.0,
  0.0,     1.0,
  1.0,     1.0,
  1.0,     0.0,
]

var PRIM_VERTICES: seq[GLfloat] = @[]
var PRIM_COLORS: seq[GLfloat] = @[]

var DRAWABLES_TABLE = newTable[GLuint, (Image, seq[Drawable])]()

var lastPrimVerticesLen = 0
var lastPrimColorsLen = 4

proc initArt* ()=
  program = newShaderProgram(
    vertex=loadShaderFromString(GL_VERTEX_SHADER, VERTEX_SHADER),
    fragment=loadShaderFromString(GL_FRAGMENT_SHADER, FRAGMENT_SHADER))

  primitive_program = newShaderProgram(
    vertex=loadShaderFromString(GL_VERTEX_SHADER, PRIM_VERTEX_SHADER),
    fragment=loadShaderFromString(GL_FRAGMENT_SHADER, PRIM_FRAGMENT_SHADER))

  rect_vao = newVertexArray()
  useVertexArray rect_vao:
    glGenBuffers(1, addr rect_vbo)
    glBindBuffer(GL_ARRAY_BUFFER, rect_vbo)
    glBufferData(
      GL_ARRAY_BUFFER,
      sizeof(RECT_VERTICES[0])*(RECT_VERTICES.len),
      addr RECT_VERTICES[0],
      GL_STATIC_DRAW)

    glEnableVertexAttribArray(0)
    glVertexAttribPointer(
      0,
      2,
      cGL_FLOAT,
      GL_FALSE,
      0,
      cast[pointer](0))

    glBindBuffer(GL_ARRAY_BUFFER, 0)

  prim_vao = newVertexArray()
  useVertexArray prim_vao:
    var v = @[0.0'f32]
    var c: seq[float32] = @[]
    prim_vbo = newVertexBufferObject[GLfloat](GL_ARRAY_BUFFER, 3, 0, v, dynamic=true)
    prim_cbo = newVertexBufferObject[GLfloat](
      GL_ARRAY_BUFFER,
      4,
      1,
      c,
      dynamic=true)

proc rotatePoint* (cx, cy, angle, px, py: float): (float, float)=
  let
    abs_angle = abs(angle)
    s = sin(abs_angle)
    c = cos(abs_angle)
    pxx = px - cx
    pyy = py - cy

  var
    nx, ny = 0.0

  if (radToDeg angle) > 0.0:
    nx = pxx * c - pyy * s
    ny = pxx * s + pyy * c
  else:
    nx = pxx * c + pyy * s
    ny = -pxx * s + pyy * c

  result = (nx + cx, ny + cy)

proc pushVertex* (x, y: int | float | float32)=
  (PRIM_VERTICES.add x.float32)
  (PRIM_VERTICES.add y.float32)
  (PRIM_VERTICES.add 0.0)

  (PRIM_COLORS.add color[0])
  (PRIM_COLORS.add color[1])
  (PRIM_COLORS.add color[2])
  (PRIM_COLORS.add color[3])

proc pushVertexRotated* (x, y: int | float | float32, rotation=0.0)=
  let rcos = cos rotation
  let rsin = sin rotation
  let cx = rcos * x.float - rsin * y.float
  let cy = rsin * x.float + rcos * y.float
  (PRIM_VERTICES.add cx)
  (PRIM_VERTICES.add cy)
  (PRIM_VERTICES.add 0.0)

# Primitives 
proc drawLine* (x1, y1, x2, y2: int | float, thickness=4.0)=
  let l = sqrt(((x2 - x1).float ^ 2) + ((y2 - y1).float ^ 2))
  let rot = arctan2(y2.float - y1.float, x2.float - x1.float)
  drawRect(x1.float, y1.float, l, thickness, rot)

proc drawCircle* (x, y, radius: int | float, resolution=360)=
  for i in countup(0, 360, 10):
    let fi = i.float
    let irad = degToRad(fi)
    pushVertex(x.float, y.float);
    pushVertex(x.float + sin(irad)*radius.float, y.float + cos(irad)*radius.float)
    pushVertex(x.float + sin(degToRad(fi + 10.0))*radius.float, y.float + cos(degToRad(fi + 10.0))*radius.float);

proc drawRect* (x, y, width, height: int | float, rotation=0.0, offsetX, offsetY=0.0)=
  if rotation == 0.0:
    pushVertex x, y + height
    pushVertex x, y
    pushVertex x + width, y
    pushVertex x + width, y
    pushVertex x, y + height
    pushVertex x + width, y + height
  else:
    let r = rotation
    let (vx1, vy1) = rotatePoint(x.float + offsetX, y.float + offsetY, r, x.float, (y + height).float)
    let (vx2, vy2) = rotatePoint(x.float + offsetX, y.float + offsetY, r, (x + width).float, y.float)
    let (vx3, vy3) = rotatePoint(x.float + offsetX, y.float + offsetY, r, (x + width).float, (y + height).float)

    pushVertex x, y
    pushVertex vx1, vy1
    pushVertex vx2, vy2
    pushVertex vx2, vy2
    pushVertex vx1, vy1
    pushVertex vx3, vy3

proc drawImage* (image: Image, x, y, width, height: int | float, rot=0.0, depth=0.0)=
  if not DRAWABLES_TABLE.hasKey image.id:
    DRAWABLES_TABLE.add(image.id, (image, @[]))

  DRAWABLES_TABLE[image.id][1].add Drawable(
    region: newRegion(0, 0, image.width, image.height),
    body: (x.float, y.float, width.float, height.float),
    transform: (rot, depth)
  )

proc drawImage* (image: Image, x, y: int | float = 0.0)=
  drawImage(image, x, y, image.width, image.height)

proc drawLineRect* (x, y, width, height: int | float, rotation=0.0, thickness=4.0)=
  let 
    fx = x.float
    fy = y.float
    fw = width.float
    fh = height.float

  drawRect(fx, fy, fw, thickness)
  drawRect(fx, fy, thickness, fh)
  drawRect(fx, fy+fh-thickness, fw, thickness)
  drawRect(fx+fw-thickness, fy, thickness, fh)

proc setDrawColor* (r, g, b=1.0, a=1.0)=
  color = (r, g, b, a)

proc setDrawColor* (c: Color)=
  color = (c.r, c.g, c.b, c.a)

template useColor* (r, g, b, a: float, body: untyped)=
  let pre = color
  setDrawColor(r, g, b, a)
  body
  color = pre

proc beginArt* ()=
  let (ww, wh) = Window.size()
  ortho_projection = ortho(0.0, ww.float32, wh.float32, 0.0, -10.0, 10.0)
  glViewport(0, 0, ww.GLsizei, wh.GLsizei)

proc flushArt* ()=
  # Drawing drawables
  useShaderProgram program:
    setUniform getUniformLoc(program, "projection"), ortho_projection
    useVertexArray rect_vao:

      for key in DRAWABLES_TABLE.keys:
        var (image, _) = DRAWABLES_TABLE[key]
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, key)

        for drawable in DRAWABLES_TABLE[key][1]:
          setUniform(
            getUniformLoc(program, "body"),
            drawable.body[0],
            drawable.body[1],
            drawable.body[2],
            drawable.body[3])

          let x = drawable.region.x.float / image.width.float
          let y = drawable.region.y.float / image.height.float
          let width = drawable.region.width.float / image.width.float
          let height = drawable.region.height.float / image.height.float

          setUniform getUniformLoc(program, "region"), x, 1 - y + (1 - height), width, height
          setUniform getUniformLoc(program, "transform"), drawable.transform[0], drawable.transform[1]

          glDrawArrays(GL_TRIANGLES, 0, 6)
        DRAWABLES_TABLE[key][1].setLen 0

      glBindTexture(GL_TEXTURE_2D, 0)

  if PRIM_VERTICES.len == 0 or PRIM_COLORS.len == 0:
    return
  
  # Drawing primitives
  useShaderProgram primitive_program:
    setUniform getUniformLoc(primitive_program, "projection"), ortho_projection

    useVertexArray prim_vao:
      useVertexBufferObject prim_vbo, GL_ARRAY_BUFFER:
        if lastPrimVerticesLen != len(PRIM_VERTICES):
          glBufferData(
              GL_ARRAY_BUFFER,
              cast[GLsizeiptr](sizeof(float32) * PRIM_VERTICES.len),
              addr PRIM_VERTICES[0],
              GL_DYNAMIC_DRAW)
        else:
          glBufferSubData(
            GL_ARRAY_BUFFER,
            0.GLintptr,
            sizeof(float32) * lastPrimVerticesLen,
            addr PRIM_VERTICES[0])

      useVertexBufferObject prim_cbo, GL_ARRAY_BUFFER:
        if lastPrimColorsLen != len(PRIM_COLORS):
          glBufferData(
              GL_ARRAY_BUFFER,
              cast[GLsizeiptr](sizeof(float32) * PRIM_COLORS.len),
              addr PRIM_COLORS[0],
              GL_DYNAMIC_DRAW)
        else:
          glBufferSubData(
            GL_ARRAY_BUFFER,
            0.GLintptr,
            sizeof(float32) * len(PRIM_COLORS),
            addr PRIM_COLORS[0])

      glDrawArrays(GL_TRIANGLES, 0, (PRIM_VERTICES.len / 3).GLsizei)

  lastPrimVerticesLen = len(PRIM_VERTICES)
  lastPrimColorsLen = len(PRIM_COLORS)

  (PRIM_VERTICES.setLen 0)
  (PRIM_COLORS.setLen 0)

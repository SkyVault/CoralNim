# Main Renderer for the Coral frame work
import
  sequtils,
  platform,
  opengl,
  math,
  cgl,
  maths

type
  Vertex* = ref object
    position*: (float, float)

  Renderer* = ref object
    rectBuffers: (GLuint, GLuint)

include private/shaders

proc drawLine* (x1, y1, x2, y2: int | float, thickness=4.0)
proc drawCircle* (x, y, radius: int | float, resolution=360)
proc drawRect* (x, y, width, height: int | float, rotation=0.0)

var ortho_projection: Mat4
var rect_vao, rect_vbo, rect_ibo : GLuint

var prim_vao, prim_vbo: GLuint

var program: GLuint
var primitive_program: GLuint

#var color = (0.0, 0.0, 0.0, 0.0)

var RECT_VERTICES = @[
    -0.5'f32,   0.5,
    -0.5,      -0.5,
     0.5,      -0.5,
     0.5,       0.5]

var RECT_INDICES = @[0'u8, 1, 2, 2, 3, 0]

var PRIM_VERTICES: seq[GLfloat] = @[]
var lastPrimVerticesLen = 0

proc initArt* ()=
  program = newShaderProgram(
    vertex=loadShaderFromString(GL_VERTEX_SHADER, VERTEX_SHADER),
    fragment=loadShaderFromString(GL_FRAGMENT_SHADER, FRAGMENT_SHADER))

  primitive_program = newShaderProgram(
    vertex=loadShaderFromString(GL_VERTEX_SHADER, PRIM_VERTEX_SHADER),
    fragment=loadShaderFromString(GL_FRAGMENT_SHADER, PRIM_FRAGMENT_SHADER))

  rect_vao = newVertexArray()
  useVertexArray rect_vao:
    rect_vbo = newVertexBufferObject[GLfloat](GL_ARRAY_BUFFER, 2, 0, RECT_VERTICES)
    rect_ibo = newElementBuffer(RECT_INDICES)

  prim_vao = newVertexArray()
  useVertexArray prim_vao:
    var v = @[0.0'f32]
    prim_vbo = newVertexBufferObject[GLfloat](GL_ARRAY_BUFFER, 3, 0, v, dynamic=true)

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

proc drawRect* (x, y, width, height: int | float, rotation=0.0)=
  if rotation == 0.0:
    pushVertex x, y + height
    pushVertex x, y
    pushVertex x + width, y
    pushVertex x + width, y
    pushVertex x, y + height
    pushVertex x + width, y + height
  else:
    let r = rotation
    let (vx1, vy1) = rotatePoint(x.float, y.float, r, x.float, (y + height).float)
    let (vx2, vy2) = rotatePoint(x.float, y.float, r, (x + width).float, y.float)
    let (vx3, vy3) = rotatePoint(x.float, y.float, r, (x + width).float, (y + height).float)

    pushVertex x, y
    pushVertex vx1, vy1
    pushVertex vx2, vy2
    pushVertex vx2, vy2
    pushVertex vx1, vy1
    pushVertex vx3, vy3

proc beginArt* ()=
  let (ww, wh) = Window.size()
  ortho_projection = ortho(0.0, ww.float32, wh.float32, 0.0, -10.0, 10.0)

proc flushArt* ()=
  #useShaderProgram program:
    #useVertexArray rect_vao:
      #useElementBuffer rect_ibo:
        #glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)

  useShaderProgram primitive_program:
    setUniform getUniformLoc(primitive_program, "projection"), ortho_projection

    useVertexArray prim_vao:
      useVertexBufferObject prim_vbo, GL_ARRAY_BUFFER:
        if lastPrimVerticesLen != len(PRIM_VERTICES):
          glBufferData(
              GL_ARRAY_BUFFER,
              cast[GLsizeiptr](sizeof(float32) * PRIM_VERTICES.len),
              addr PRIM_VERTICES[0],
              GL_STATIC_DRAW)
        else:
          glBufferSubData(
            GL_ARRAY_BUFFER,
            0.GLintptr,
            sizeof(float32) * lastPrimVerticesLen,
            addr PRIM_VERTICES[0])

      glDrawArrays(GL_TRIANGLES, 0, (PRIM_VERTICES.len / 3).GLsizei)

  lastPrimVerticesLen = len(PRIM_VERTICES)
  (PRIM_VERTICES.setLen 0)

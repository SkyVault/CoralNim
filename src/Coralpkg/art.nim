# Main Renderer for the Coral frame work
import
  sequtils,
  opengl,
  cgl,
  sdl2/[sdl]

type
  Vertex* = ref object
    position*: (float, float)

  Renderer* = ref object
    rectBuffers: (GLuint, GLuint)

var rect_vao, rect_vbo, rect_ibo : GLuint

var RECT_VERTICES = @[
    -0.5'f32,   0.5,
    -0.5,      -0.5,
     0.5,      -0.5,
     0.5,       0.5
]

var RECT_INDICES = @[
    0'u8, 1, 2, 2, 3, 0
]

proc init* ()=
  rect_vao = newVertexArray()
  useVertexArray rect_vao:
    rect_vbo = newVertexBufferObject[GLfloat](GL_ARRAY_BUFFER, 2, 0, RECT_VERTICES)
    rect_ibo = newElementBuffer(RECT_INDICES)

proc begin* ()=
  discard

proc flush* ()=
  useVertexArray rect_vao:
    useElementBuffer rect_ibo:
      glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)

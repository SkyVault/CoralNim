# Main Renderer for the Coral frame work
import
  sequtils,
  platform,
  opengl,
  cgl,
  maths

type
  Vertex* = ref object
    position*: (float, float)

  Renderer* = ref object
    rectBuffers: (GLuint, GLuint)

const VERTEX_SHADER="""
#version 330 core
layout (location = 0) in vec3 Vertices;

void main(void) {
  gl_Position = vec4(Vertices, 1.0); 
}
"""

const FRAGMENT_SHADER="""
#version 330 core
out vec4 Result; 

void main(void) {
  Result = vec4(1.0, 0.5, 0.0, 1.0);
}
"""

var rect_vao, rect_vbo, rect_ibo : GLuint
var program: GLuint

var RECT_VERTICES = @[
    -0.5'f32,   0.5,
    -0.5,      -0.5,
     0.5,      -0.5,
     0.5,       0.5]

var RECT_INDICES = @[0'u8, 1, 2, 2, 3, 0]

proc applyProjection()=
  let (ww, wh) = Window.size()
  #let ortho = ortho()

proc init* ()=
  program = newShaderProgram(
    vertex=loadShaderFromString(GL_VERTEX_SHADER, VERTEX_SHADER),
    fragment=loadShaderFromString(GL_FRAGMENT_SHADER, FRAGMENT_SHADER))

  rect_vao = newVertexArray()
  useVertexArray rect_vao:
    rect_vbo = newVertexBufferObject[GLfloat](GL_ARRAY_BUFFER, 2, 0, RECT_VERTICES)
    rect_ibo = newElementBuffer(RECT_INDICES)

proc begin* ()=
  discard

proc flush* ()=
  useShaderProgram program:
    useVertexArray rect_vao:
      useElementBuffer rect_ibo:
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)

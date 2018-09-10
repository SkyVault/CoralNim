import
  ../src/Coral,
  ../src/Coralpkg/[cgl, platform],
  opengl,
  math

initGame(1280, 720, ":)", ContextSettings(majorVersion: 3, minorVersion: 3, core: true))

let shaderProgram = newShaderProgram(
  vertex=loadShaderFromString(GL_VERTEX_SHADER, """
  #version 330 core
  layout (location = 0) in vec3 Vertices;
  
  void main(void) {
    gl_Position = vec4(Vertices, 1.0); 
  }
  """),

  fragment=loadShaderFromString(GL_FRAGMENT_SHADER, """
  #version 330 core
//  vec4 Result; 

  void main(void) {
    vec4 Result = vec4(1.0, 0.5, 0.0, 1.0);
    gl_FragColor = Result;
  }

  """))

var vertices: seq[GLfloat] = @[
  -1.0'f32,-1.0'f32, 0.0'f32,
   1.0'f32,-1.0'f32, 0.0'f32,
   0.0'f32, 1.0'f32, 0.0'f32]

let vao = newVertexArray()
useVertexArray vao:
  discard newVertexBufferObject[GLfloat](GL_ARRAY_BUFFER, 3, 0, vertices)

while updateGame():
  glDisable(GL_CULL_FACE)

  clearColorAndDepthBuffers (0.1, 0.1, 0.1, 1.0)

  useShaderProgram shaderProgram:
    useVertexArray vao:
      glDrawArrays(GL_TRIANGLES, 0, GLsizei(3))

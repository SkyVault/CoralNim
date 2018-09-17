import
  ../src/Coral,
  ../src/Coralpkg/[cgl, platform, art],
  opengl,
  math,
  strformat

initGame(1280, 720, ":)", ContextSettings(majorVersion: 3, minorVersion: 3, core: true))

initArt()

var timer = 0.0

while updateGame():

  Window.title = &"FPS: {Time.framesPerSecond.int}"
  let dt = Time.deltaTime
  timer += dt

  glDisable(GL_CULL_FACE)

  clearColorAndDepthBuffers (0.1, 0.1, 0.1, 1.0)

  #glBegin(GL_TRIANGLES)
  #glVertex2f(-1.0, -1.0)
  #glVertex2f( 0.0,  1.0)
  #glVertex2f( 1.0, -1.0)
  #glEnd()

  beginArt()

  drawRect 400, 300, 100, 100, timer

  drawLine 100, 200, 400, 400
  drawCircle 400, 400, 10

  #drawCircle 100.0 + cos(timer) * 150.0, 100.0, 100.0
  #drawCircle 200.0 + cos(timer) * 150.0, 200.0, 100.0
  #drawCircle 300.0 + cos(timer) * 150.0, 300.0, 100.0
  drawCircle 800.0 + cos(timer) * 150.0, 400.0, 100.0

  flushArt()

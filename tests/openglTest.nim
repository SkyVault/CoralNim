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

  beginArt()

  setDrawColor 1.0, 0.5, 0.0, 1.0
  drawRect 100, 100, 300, 300

  setDrawColor 0.0, 1.0, 1.0, 1.0
  drawCircle 800, 400, 100

  flushArt()

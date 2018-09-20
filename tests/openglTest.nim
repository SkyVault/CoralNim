import
  ../src/Coral,
  ../src/Coralpkg/[cgl, platform, art],
  opengl,
  math,
  strformat,
  os,
  ospaths

initGame(1280, 720, ":)", ContextSettings(majorVersion: 3, minorVersion: 3, core: true))
initArt()

var timer = 0.0

let lolwut = loadImage(joinPath(getAppDir(), "lolwut.png"))

while updateGame():
  Window.title = &"FPS: {Time.framesPerSecond.int}"
 
  let dt = Time.deltaTime
  timer += dt

  #glDisable(GL_CULL_FACE)

  clearColorAndDepthBuffers (0.1, 0.1, 0.1, 1.0)

  beginArt()

  #setDrawColor (colorFromHex "FF00FF")
  #drawRect 100, 100, 300, 300

  #setDrawColor P8_Indigo
  #drawCircle 800, 400, 100

  drawImage lolwut, 0, 0, 200, 200

  #flushArt()

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

  drawImage(lolwut, 100.0, 100.0, 500.0, 500.0, rot=timer)

  #setDrawColor (colorFromHex "FF00FF")
  #drawRect 100, 100, 300, 300

  #setDrawColor P8_Indigo
  #drawCircle 800, 400, 100

  #for y in 0..100:
    #for x in 0..200:
      #drawImage lolwut, x*10, y*10, 10, 10

  flushArt()

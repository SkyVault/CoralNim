import strformat
import
  ../../src/Coral,
  ../../src/Coralpkg/[art, cgl, platform]

initGame(1280, 720, ":)", ContextSettings(majorVersion: 3, minorVersion: 3, core: true))
initArt()

while updateGame():
  clearColorAndDepthBuffers (0.1, 0.1, 0.1, 1.0)

  Window.title = &"FPS: {Time.framesPerSecond.int}"

  beginArt()

  setDrawColor (colorFromHex "00FFFF")
  drawRect 300, 200, 300, 300, 45.0

  endArt()

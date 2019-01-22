import
  ../../src/Coral,
  ../../src/Coralpkg/[platform, cgl, art]

initGame(1280, 720, ":)", ContextSettings(majorVersion: 3, minorVersion: 3, core: true))
initArt()

while updateGame():
  beginArt()

  setDrawColor(1, 0, 0)
  drawRect(0, 0, 100, 100)

  endArt()

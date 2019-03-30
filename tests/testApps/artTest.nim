import
  ../../src/Coral,
  ../../src/Coralpkg/[platform, cgl, art]

initGame(1280, 720, ":)")
initArt()

let test = loadImage "tests/testApps/lolwut.png"

while updateGame():
  if Time.ticks mod 20 == 0:
    echo $Time.framesPerSecond

  beginArt()
  clearColorAndDepthBuffers()

  setDrawColor(1, 0, 0)
  drawRect(40, 40, 100, 100, 20.0, 50, 50)

  setDrawColor(0, 1, 0)
  drawCircle(400, 300, 100)

  setDrawColor(0, 0, 1)
  drawLineRect(200, 300, 600, 400)

  setDrawColor(1, 0, 1)
  drawLine(400, 3, 100, 200)

  drawCircle(500, 100, 64, 6)

  setDrawColor(0, 1, 1)
  drawTriangle(
    50, 0,
    0, 100,
    100, 100)

  for i in 0..2000:
    drawImage test, 100+i/2, 100, 100, 100

  endArt()

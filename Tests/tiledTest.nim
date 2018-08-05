import 
    ../Coral/[game, graphics, renderer, tiled, gameMath],
    os

var map: TileMap
var font: Font

Coral.load = proc() =
  map = loadTileMap getAppDir() & "/smile.tmx"
  font = loadFont(getApplicationDir() & "/arial.ttf", 32)

Coral.draw = proc()=
  Coral.r2d.drawTileMap(map)

  Coral.r2d.drawString(font, "Hello", newV2(10, 10))

  if Coral.clock.ticks mod 10 == 0:
    Coral.windowTitle = $Coral.clock.currentFps().int

Coral.newGame(1280, 720, "").run()

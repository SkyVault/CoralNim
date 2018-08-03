import 
    ../Coral/[game, graphics, renderer, tiled],
    os

var map: TiledMap
var img: Image

Coral.load = proc() =
  img = loadImage getAppDir() & "/tileset.png"
  map = loadTiledMap getAppDir() & "/testMap.tmx"

Coral.draw = proc()=
  Coral.r2d.drawImage(img, 10.0, 10.0, 500.0, 500.0, 0.0, newColor())

Coral.newGame(1280, 720, "").run()

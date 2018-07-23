import 
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/tiled

var map: TiledMap
Coral.load = proc() = discard
    # map = loadTiledMap()

Coral.newGame(1280, 720, "").run()
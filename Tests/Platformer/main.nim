import 
    ../../Coral/game,
    ../../Coral/graphics,
    ../../Coral/renderer,
    ../../Coral/tiled,
    os

var map: TiledMap

Coral.load = proc()=
    map = loadTiledMap getCurrentDir() & "/Tests/Platformer/assets/map1.tmx"

Coral.render = proc()=
    Coral.r2d.drawTiledMap map

Coral.createGame(1280, 720, "Hello World", config())
    .run()
import 
    ../../Coral/game,
    ../../Coral/tiled,
    os

var map: TiledMap

Coral.load = proc()=
    map = loadTiledMap getCurrentDir() & "/Tests/Platformer/assets/map1.tmx"

Coral.createGame(1280, 720, "Hello World", config())
    .run()
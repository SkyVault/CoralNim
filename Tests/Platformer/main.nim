import 
    ../../Coral/game,
    ../../Coral/graphics,
    ../../Coral/renderer,
    ../../Coral/tiled,
    os,
    opengl

var map: TiledMap

Coral.load = proc()=
    map = loadTiledMap getCurrentDir() & "/assets/map1.tmx"

Coral.update = proc()=
    if Coral.isKeyPressed CoralKey.Escape:
        Coral.quit()

Coral.render = proc()=
    Coral.windowTitle = $Coral.clock.averageFps
    Coral.r2d.drawTiledMap(map, White)

Coral.createGame(720, 720, "Hello World", config(resizable = true))
    .run()

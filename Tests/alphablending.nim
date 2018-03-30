import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    random,
    test,
    os,
    math

var image: Image
Coral.load = proc()=
    image = CoralLoadImage getAppDir() & "/wat.png"

Coral.render = proc()=
    for i in 0 .. 100:
        Coral.r2d.drawImage(
            image,
            newV2(100 + i * 40, 100),
            newV2(200, 200),
            0.0,
            newColor(1.0, 1.0, 1.0, 0.4)
        )

Coral.createGame(1280, 720, "", config()).run()
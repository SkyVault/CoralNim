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
    image = loadImage getAppDir() & "/wat.png"

    # Coral.assets.add("image", image)

Coral.render = proc()=
    Coral.windowTitle = "😁"
    # discard Coral.assets.get(Image, "image")

    for i in 0 .. 100:
        Coral.r2d.drawImage(
            image,
            100 + i.float * 40.0, 100.0,
            200.0, 200.0,
            0.0,
            newColor(1.0, 1.0, 1.0, 0.4)
        )

Coral.createGame(1280, 720, "", config()).run()
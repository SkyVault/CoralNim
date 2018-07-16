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

var font: Font

Coral.load = proc()= 
    font = CoralLoadFont(getApplicationDir() & "/arial.ttf", 60)

Coral.draw = proc()=
    Coral.r2d.setBackgroundColor(P8Indigo)

    # Coral.r2d.drawRect(0.0, 0.0, font.image.width.float, font.image.height.float, 0.0, P8Black)
    # Coral.r2d.drawImage(font.image, newV2(0, font.image.height), newV2(font.image.width, -font.image.height), 0.0, newColor())

Coral.createGame(1280, 720, "Font Test", config()).run()
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

    const text = "Fonts are now correctly positioned!"
    Coral.r2d.drawString(font, text, newV2(0.0, 0.0))

Coral.createGame(1280, 720, "Font Test", config()).run()
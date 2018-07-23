import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    random,
    os,
    math

var font: Font

Coral.load = proc()= 
    font = loadFont(getApplicationDir() & "/arial.ttf", 60)

Coral.draw = proc()=
    Coral.r2d.setBackgroundColor(P8Indigo)

    const text = "Fonts are now correctly positioned!"
    Coral.r2d.drawRect(0, 0, 200, 200, 0.0, P8Red)
    Coral.r2d.drawString(font, text, newV2(0.0, 0.0))
    # Coral.r2d.drawRect(0, 0, 200, 200, 0.0, P8Red)

Coral.newGame(1280, 720, "Font Test", config()).run()
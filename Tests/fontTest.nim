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

    for x in 0..<10:
      for i in 0..<40:
        Coral.r2d.drawString(font, text, newV2(x.float * 120.0, 64.0 + i.float * 16.0), scale=0.25)

    if Coral.clock.ticks mod 10 == 0:
      Coral.windowTitle = $Coral.clock.currentFps


Coral.newGame(1280, 720, "Font Test", config()).run()

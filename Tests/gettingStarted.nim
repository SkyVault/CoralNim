import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer

Coral.draw = proc()=
    Coral.r2d.setBackgroundColor(P8Peach)
    Coral.r2d.drawRect(100, 100, 100, 100, 45.0, Red)

Coral.createGame(800, 600, "My Coral Game").run()
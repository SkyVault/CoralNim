import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath


let theGame = newGame(
    1280, 
    720, 
    "Breakout!", 
    config())

var r2d: R2D

theGame.load = proc()= 
    r2d = newR2D()

theGame.update = proc()= 
    echo theGame.clock.currentFPS.int, " ", theGame.clock.dt

theGame.draw = proc()= 
    r2d.setBackgroundColor(DarkGray())
    r2d.clear()

    r2d.begin((1280, 720))
    r2d.drawRect(newV2(100, 100), newV2(100, 100), theGame.clock.timer, Red())
    r2d.flush()

theGame.destroy = proc()=
    discard

theGame.run()
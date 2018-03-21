import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    math,
    glfw

let theGame = newGame(
    1280, 
    720, 
    "Breakout!", 
    config())

var r2d: R2D

theGame.load = proc()= 
    r2d = newR2D()

theGame.update = proc()= 
    theGame.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $theGame.clock.currentFPS

    if theGame.isKeyReleased keyEscape:
        quit(theGame)

theGame.draw = proc()= 
    r2d.drawRect(newV2(100, 100), newV2(100, 100), theGame.clock.timer, Red())

theGame.destroy = proc()=
    discard

theGame.run()
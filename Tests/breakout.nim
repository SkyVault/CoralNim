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

let wat = loadImage "Tests/wat.png"

theGame.load = proc()= discard

theGame.update = proc()= 
    theGame.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $theGame.clock.currentFPS

    if theGame.isKeyReleased keyEscape:
        quit(theGame)

theGame.draw = proc()= 
    theGame.r2d.setBackgroundColor(P8Peach)
    theGame.r2d.drawLineRect(1000, 100, 200, 200, theGame.clock.timer, Red())
    theGame.r2d.drawImage(wat, newV2(0, 0), newV2(500, 500), 0.0, White)

# theGame.destroy = proc()=
#     discard

theGame.run()
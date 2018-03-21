import
    ../Coral/game

let theGame = newGame(
    1280, 
    720, 
    "Breakout!", 
    config())

theGame.load = proc()= 
    discard

theGame.update = proc()= 
    echo theGame.clock.currentFPS.int, " ", theGame.clock.dt

theGame.draw = proc()= 
    discard

theGame.destroy = proc()=
    discard

theGame.run()
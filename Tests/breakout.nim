import
    ../Coral/game

let theGame = newGame(
    1280, 
    720, 
    "Breakout!", 
    config())

theGame.load = proc()= discard
theGame.update = proc()= discard
theGame.draw = proc()= discard

theGame.run()
import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    math

let theGame = newGame(
    1280, 
    720, 
    "Breakout!", 
    config())

type 
    Temp = ref object of CoralComponent
        test: string

let world = newWorld()

let entity = world.create()
entity.add(Temp(test: "Hello World"))

let wat = loadImage "Tests/wat.png"
let camera = Camera2D(
    position  : newV2(0, 0),
    zoom      : 1,
    rotation  : 0.0
)

theGame.load = proc()=
    discard

theGame.update = proc()= 
    theGame.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $theGame.clock.currentFPS

    if theGame.isKeyReleased CoralKey.Escape:
        quit(theGame)

theGame.draw = proc()= 
    theGame.r2d.setBackgroundColor(P8Peach)
    theGame.r2d.view = camera
    theGame.r2d.drawLineRect(1000, 100, 200, 200, theGame.clock.timer, Red())
    theGame.r2d.drawImage(wat, newV2(0, 0), newV2(500, 500), 0.0, White)

# theGame.destroy = proc()=
#     discard

theGame.run()
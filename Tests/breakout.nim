import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    math,
    glfw

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

var theAudio: CoralAudio

theGame.load = proc()=
    theAudio = theGame.audio.loadAudio "Tests/pixel_caves.ogg"
    # theAudio.volume = 0
    theAudio.play()

theGame.update = proc()= 
    theGame.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $theGame.clock.currentFPS

    if theGame.isKeyReleased keyEscape:
        quit(theGame)

    if theGame.isKeyPressed keyP:
        theAudio.togglePause()

theGame.draw = proc()= 
    theGame.r2d.setBackgroundColor(P8Peach)
    theGame.r2d.view = camera
    theGame.r2d.drawLineRect(1000, 100, 200, 200, theGame.clock.timer, Red())
    theGame.r2d.drawImage(wat, newV2(0, 0), newV2(500, 500), 0.0, White)

# theGame.destroy = proc()=
#     discard

theGame.run()
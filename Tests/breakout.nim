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
    Body = ref object of CoralComponent
        position, size: V2

    Paddle = ref object of CoralComponent
        velocity: V2

    Um = ref object of CoralComponent

let world = newCoralWorld()

## Paddle controller
world.createSystem(
    @["Body", "Paddle"],

    load = proc(s: CoralSystem, e: CoralEntity)=
        echo("Matched dude!")
)

let ent = world.createEntity()
ent.add(Body(position: newV2(0,0), size: newV2(100, 100)))
ent.add(Paddle(velocity: newV2(0, 0)))
ent.add(Um())

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

    world.update()

theGame.draw = proc()= 
    theGame.r2d.setBackgroundColor(P8Peach)
    theGame.r2d.view = camera
    theGame.r2d.drawLineRect(1000, 100, 200, 200, theGame.clock.timer, Red())
    theGame.r2d.drawImage(wat, newV2(0, 0), newV2(500, 500), 0.0, White)

    world.render()

# theGame.destroy = proc()=
#     discard

theGame.run()
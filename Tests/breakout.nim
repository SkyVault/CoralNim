import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    test,
    math

CoralCreateGame(
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

for i in 0..10:
    let ent = Coral.world.createEntity()
    ent.add(Body(position: newV2(0,0), size: newV2(100, 100)))
    ent.add(Paddle(velocity: newV2(0, 0)))
    ent.add(Um())

# let wat = loadImage "Tests/wat.png"
let camera = Camera2D(
    position  : newV2(0, 0),
    zoom      : 1,
    rotation  : 0.0
)

Coral.load = proc()=
    discard

Coral.update = proc()= 
    Coral.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $Coral.clock.averageFps

    if Coral.isKeyReleased CoralKey.Escape:
        quit(Coral)

Coral.draw = proc()= 
    Coral.r2d.setBackgroundColor(P8Peach)
    Coral.r2d.view = camera
    Coral.r2d.drawLineRect(1000, 100, 200, 200, Coral.clock.timer, Red())

Coral.run()
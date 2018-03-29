import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    test,
    os,
    math

type 
    Body = ref object of CoralComponent
        position, size: V2

    Paddle = ref object of CoralComponent
        velocity: V2

    Um = ref object of CoralComponent

let ent = Coral.world.createEntity()
ent.add(Body(position: newV2(0,0), size: newV2(100, 100)))
ent.add(Paddle(velocity: newV2(0, 0)))
ent.add(Um())

let ent2 = Coral.world.createEntity(@[
    Body(position: newV2(0,0), size: newV2(100, 100)),
    Paddle(velocity: newV2(0, 0)),
    Um()
])

let camera = Camera2D(
    position  : newV2(0, 0),
    zoom      : 1,
    rotation  : 0.0
)

var wat: Image
var pos = newV2(0, 0)

Coral.load = proc()= 
    Coral.r2d.rotationMode = CoralRotationMode.Degrees
    wat = CoralLoadImage "Tests/wat.png"

Coral.update = proc()= 
    Coral.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $Coral.clock.averageFps

    if Coral.isKeyReleased CoralKey.Escape:
        quit(Coral)

    if Coral.isKeyDown CoralKey.Left:
        pos.x -= Coral.clock.averageDt * 100

    if Coral.isKeyDown CoralKey.Right:
        pos.x += Coral.clock.averageDt * 100

Coral.draw = proc()= 
    Coral.r2d.setBackgroundColor(P8Peach)
    Coral.r2d.view = camera
    Coral.r2d.drawLineRect(1000, 100, 200, 200, 20.0 * Coral.clock.timer, Red)
    Coral.r2d.drawImage(wat, pos, newV2(256, 256), 45.0, White)

Coral.createGame(1280, 720, "Breakout!", config()).run()

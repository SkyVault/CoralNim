import 
    ../Coral/game,
    ../Coral/renderer,
    ../Coral/graphics,
    ../Coral/gameMath,
    sdl2/sdl,
    math,
    os

var image: Image
Coral.load = proc()=
    image = CoralLoadImage(getCurrentDir() & "/Tests/wat.png")

    Coral.clock.addTimer(1000, callback = proc()=
        echo "hello"
    )

Coral.update = proc()=
    # echo Coral.windowSize
    if Coral.isKeyPressed sdl.K_Left:
        echo "LEFT! Pressed"

    if Coral.isKeyReleased sdl.K_Left:
        echo "LEFT! Released"

    if Coral.isMouseRightReleased:
        echo "right mouse released"

    if Coral.isMouseRightPressed:
        echo "right mouse pressed"

    if Coral.isMouseLeftReleased:
        echo "left mouse released"

    if Coral.isMouseLeftPressed:
        echo "left mouse pressed"

    # Coral.windowPosition = (((math.cos(Coral.clock.timer) * 200.0) + 200).int, Coral.windowPosition[1])

Coral.render = proc()=
    Coral.r2d.setBackgroundColor(P8Peach)
    Coral.windowTitle = "Hello my mellow fellow"
    Coral.r2d.drawImage(
        image,
        10.0, 10.0, 300.0, 250.0,
        0.0,
        White
    )

    Coral.r2d.drawRect(200, 300, 300, 300, 0.0, P8Orange)
    Coral.r2d.drawLineRect(300, 350, 300, 300, Coral.clock.timer * 100.0, P8Blue)

Coral.createGame(
    1280, 
    720, 
    "Moving to SDL2", 
    config(
        resizable = true, 
        fullscreen = false
    )).run()
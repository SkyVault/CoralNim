import 
    ../Coral/game,
    ../Coral/renderer,
    ../Coral/graphics,
    ../Coral/gameMath,
    sdl2/sdl,
    os

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

var image: Image
Coral.load = proc()=
    image = CoralLoadImage(getCurrentDir() & "/Tests/wat.png")

Coral.render = proc()=
    Coral.r2d.setBackgroundColor(P8Peach)
    Coral.r2d.drawImage(
        image,
        10.0, 10.0, 300.0, 250.0,
        0.0,
        White
    )

Coral.createGame(
    11 * (32 + 8), 
    720, 
    "Moving to SDL2", 
    config(
        resizable = true, 
        fullscreen = false
    )).run()
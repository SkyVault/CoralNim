import 
    ../Coral/game,
    ../Coral/renderer,
    ../Coral/graphics,
    ../Coral/gameMath,
    sdl2/sdl

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

Coral.render = proc()=
    Coral.r2d.drawRect(
        10, 10, 200, 100, 0.0,
        P8Green
    )

Coral.createGame(
    11 * (32 + 8), 
    720, 
    "Moving to SDL2", 
    config(
        resizable = true, 
        fullscreen = false
    )).run()
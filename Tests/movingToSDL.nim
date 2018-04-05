import 
    ../Coral/game,
    sdl2/sdl

Coral.update = proc()=
    # echo Coral.windowSize
    if Coral.isKeyPressed sdl.K_Left:
        echo "LEFT! Pressed"

    if Coral.isKeyReleased sdl.K_Left:
        echo "LEFT! Released"

Coral.createGame(
    11 * (32 + 8), 
    720, 
    "Moving to SDL2", 
    config(
        resizable = true, 
        fullscreen = false
    )).run()
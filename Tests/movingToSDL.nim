import 
    ../Coral/game,
    sdl2/sdl

Coral.update = proc()=
    # echo Coral.windowSize
    if Coral.isKeyDown sdl.K_Left:
        echo "LEFT!"

Coral.createGame(
    11 * (32 + 8), 
    720, 
    "Moving to SDL2", 
    config(
        resizable = true, 
        fullscreen = false
    )).run()
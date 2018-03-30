# import nimprof
import 
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    os

var image: Image

Coral.load = proc()=
    image = CoralLoadImage getAppDir() & "/smaller.png"

Coral.render = proc()=
    Coral.windowTitle = $Coral.clock.averageFps
    
    if Coral.isKeyPressed CoralKey.Escape:
        Coral.quit()

    # randomize(0xcafebabe)
    let size = newV2(32, 32)

    # 40_000 sprites
    for y in 0 .. 200:
        for x in 0 .. 200:

            let xx = x * 4
            let yy = y * 4

            Coral.r2d.drawImage(image, newV2(xx, yy), size, Coral.clock.timer * 100, P8White)
            # Coral.r2d.drawSprite(image, newRegion(0, 0, 32, 32), newV2(xx, yy), size, Coral.clock.timer * 100, P8White)

Coral.createGame(1280, 720, "Benchmarking!", config()).run()

import 
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    random,
    os

var image: Image

Coral.load = proc()=
    image = CoralLoadImage getAppDir() & "/wat.png"

Coral.render = proc()=
    Coral.windowTitle = $Coral.clock.averageFps
    
    if Coral.isKeyPressed CoralKey.Escape:
        Coral.quit()

    randomize(0xcafebabe)
    let size = newV2(32, 32)
    for i in 0 .. 5000:
        let x = rand(Coral.windowSize[0].float - 32.0)
        let y = rand(Coral.windowSize[1].float - 32.0)

        Coral.r2d.drawImage(image, newV2(x, y), size, rand(360.0), White)

Coral.createGame(1280, 720, "Benchmarking!", config()).run()

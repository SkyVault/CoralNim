import 
    ../Coral/[game, renderer, graphics, gameMath],
    math

var camera: Camera2D

Coral.load = proc =
  camera = newCamera2D(0, 0)
  camera.offset = newV2(
    float(Coral.windowSize[0]) * 0.5,
    float(Coral.windowSize[1]) * 0.5,
  )

Coral.update = proc =
  let timer = Coral.clock.timer * 0.2
  #camera.position.x = math.cos(timer) * 500.0 - 256.0
  #camera.position.y = math.sin(timer) * 500.0 - 256.0

  #camera.zoom = math.cos(timer) * 0.5 + 1.0
  camera.zoom = 4.0
  camera.rotation = math.sin(timer)

Coral.draw = proc =
  Coral.r2d.view = camera

  for y in 0..<100:
    for x in 0..<100:
      Coral.r2d.drawRect(
        float x*50,
        float y*50,
        50,
        50,
        0.0,
        newColor(float(x) / 100.0 + 0.2, (float(x + y) / 2.0) / 100.0 + 0.2, float(y) / 100.0 + 0.2))

Coral.newGame(1280, 720, "").run()

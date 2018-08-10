import 
    ../Coral/[game, renderer, graphics, gameMath],
    math

var camera: Camera2D

Coral.load = proc =
  camera = newCamera2D(0, 0)

Coral.update = proc =
  camera.position.x = math.cos(Coral.clock.timer) * 100
  camera.position.y = math.sin(Coral.clock.timer) * 100

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
        newColor(float(x) / 100.0, (float(x + y) / 2.0) / 100.0, float(y) / 100.0))

Coral.newGame(1280, 720, "").run()

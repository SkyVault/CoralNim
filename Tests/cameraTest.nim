import 
    ../Coral/[game, renderer, graphics]

var camera: Camera2D

Coral.load = proc =
  camera = newCamera2D(0, 0)

Coral.newGame(1280, 720, "").run()

import
  ../../src/Coral,
  ../../src/Coralpkg/platform

initGame(1280, 720, ":)")

while updateGame():
  # discard Window.size()
  Window.size = (100, 100)
  Window.title = "Hello"

  echo Time.deltaTime

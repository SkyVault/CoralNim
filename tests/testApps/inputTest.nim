import
  ../../src/Coral,
  ../../src/Coralpkg/platform,
  ../../src/Coralpkg/input

initGame(1280, 720, ":)")

while updateGame():
  if Input.isKeyPressed(Key.Escape):
    quitGame()

  if Input.isMouseRightPressed():
    echo "Mouse Right Pressed!"

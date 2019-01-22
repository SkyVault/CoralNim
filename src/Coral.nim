# Hello Nim!
import Coralpkg/[platform, input, ecs, art]

include Coralpkg/private/clock

type
  Coral= ref object
    running: bool

var coral: Coral
var clock: Clock

template Time* (): auto = clock

proc initGame* (width, height: int, title: string, contextSettings = ContextSettings(
  majorVersion: 4,
  minorVersion: 5,
  core: true
))=

  newWindow((width, height), title, contextSettings)

  coral = Coral(
    running: true)

  clock = newClock()

proc quitGame* ()=
  coral.running = false

proc updateGame* (): bool=
  result = coral.running

  input.update()
  update(clock, platform.getTime())

  if isEntityWorldInitialized():
    update(World)

    if isArtInitialized():
      beginArt()
      draw(World)
      endArt()

  defer: platform.update()
  return Window.shouldClose == false

template gameLoop* (body: untyped)=
  while coral.running:
    discard updateGame()
    body

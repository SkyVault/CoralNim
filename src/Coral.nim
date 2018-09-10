# Hello Nim!
import Coralpkg/[platform, input]

type
  Coral= ref object
    running: bool

var coral: Coral

proc initGame* (width, height: int, title: string, contextSettings = ContextSettings(
  majorVersion: 4,
  minorVersion: 5,
  core: true
))=

  newWindow((width, height), title, contextSettings)

  coral = Coral(
    running: true)

proc quitGame* ()=
  coral.running = false

proc updateGame* (): bool=
  result = coral.running

  input.update()

  defer: platform.update()
  return Window.shouldClose == false

# Hello Nim!
import Coralpkg/[platform, input]

import sdl2/sdl

type
  Coral= ref object
    running: bool

var coral: Coral

proc initGame* (width, height: int, title: string)=
  newWindow((width, height), title)

  coral = Coral(
    running: true)

proc quitGame* ()=
  coral.running = false

proc updateGame* (): bool=
  result = coral.running

  input.update()

  var ev: sdl.Event
  while sdl.pollEvent(addr ev) != 0:
    case ev.kind:
    of sdl.Quit:
      coral.running = false
      return false

    else:
      discard

    input.processEvent(ev)

  defer: platform.update()


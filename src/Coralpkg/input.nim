include private/key_map

import
  sdl2/sdl,
  tables

type
  KeyState* = ref object of RootObj
    state, last: int

  MouseState*  = ref object of KeyState
  ButtonState* = ref object of KeyState

  ControllerState* = ref object
    A, B, X, Y: ButtonState
    Start, Select: ButtonState
    LTrigger, RTrigger, LShoulder, RShoulder: ButtonState

  InputManager* = ref object
    mouseX, mouseY: float64
    lastMouseX, lastMouseY: float
    lastNumberOfControllers: int
    mouseLeft, mouseRight: MouseState
    keyMap: Table[int, KeyState]
    controllers: seq[sdl.GameController]

var input = InputManager(
  mouseX: 0, mouseY: 0,
  lastMouseX: 0, lastMouseY: 0,
  lastNumberOfControllers: 0,
  mouseLeft: MouseState(state : 0, last : 0),
  mouseRight: MouseState(state : 0, last : 0),
  keyMap: initTable[int, KeyState](),
  controllers: newSeq[sdl.GameController]())

proc newKeyState(state=0, last=0): KeyState=
  result = KeyState(state: state, last: last)

template Input* (): auto= input

proc mouseX* (input: InputManager): float= return input.mouse_x
proc mouseY* (input: InputManager): float= return input.mouse_y

proc mousePos* (input: InputManager): (float, float)=
    return (input.mouseX, input.mouseY)

proc mouseDeltaX* (input: InputManager): float=return input.mouse_x - input.last_mouse_x
proc mouseDeltaY* (input: InputManager): float=return input.mouse_y - input.last_mouse_y
proc mouseDeltaPos* (input: InputManager): (float, float)=
    return (
        mouseDeltaX(input),
        mouseDeltaY(input)
    )

proc getKeyInRange(key: cint): int=
    if key > (1 shl 30):
        return ((sdl.K_Delete.int) + (key - (1 shl 30))).int
    else:
        return key.int 

proc isMouseLeftDown* (input: InputManager): bool=
    return input.mouse_left.state == 1

proc isMouseLeftUp* (input: InputManager): bool=
    return not isMouseLeftDown(input)

proc isMouseRightDown* (input: InputManager): bool=
    return input.mouse_right.state == 1

proc isMouseRightUp* (input: InputManager): bool=
    return not isMouseRightDown(input)

proc isMouseLeftPressed* (input: InputManager): bool =
    result =
        input.mouse_left.state == 1 and
        input.mouse_left.last == 0

proc isMouseLeftReleased* (input: InputManager): bool =
    result =
        input.mouse_left.state == 0 and
        input.mouse_left.last == 1

proc isMouseRightPressed* (input: InputManager): bool =
    result =
        input.mouse_right.state == 1 and
        input.mouse_right.last == 0

proc isMouseRightReleased* (input: InputManager): bool =
    result =
        input.mouse_right.state == 0 and
        input.mouse_right.last == 1

proc isKeyDown* (input: InputManager, key: Key): bool =
    var ckey = getKeyInRange(key.cint)
    if not input.keyMap.contains ckey:
        return false
    else:
        return
            input.keyMap[ckey].state == 1

proc isKeyUp* (input: InputManager, key: Key): bool =
    return not isKeyDown(input, key)

proc isKeyReleased* (input: InputManager, key: Key): bool=
    var ckey = getKeyInRange(key.cint)
    if not input.keyMap.contains ckey:
        return false
    else:
        let state = input.keyMap[ckey]
        result =
            state.state == 0 and 
            state.last  == 1

proc isKeyPressed* (input: InputManager, key: Key): bool=
    var ckey = getKeyInRange(key.cint)
    if not input.keyMap.contains ckey:
        return false
    else:
        let state = input.keyMap[ckey]
        result =
            state.state == 1 and 
            state.last  == 0

proc update* ()=
  for key, state in input.keyMap.mpairs:
      state.last = state.state

  input.mouse_left.last = input.mouse_left.state
  input.mouse_right.last = input.mouse_right.state

  # get the mouse position
  var x, y: cint
  discard sdl.getMouseState(addr(x), addr(y))

  input.last_mouse_x = input.mouse_x
  input.last_mouse_y = input.mouse_y
  input.mouse_x = x.float
  input.mouse_y = y.float

  if input.last_number_of_controllers < sdl.numJoysticks():
      input.last_number_of_controllers = sdl.numJoysticks()

      let index = input.controllers.len
      if not sdl.isGameController(index):
          echo "Unsupported controller interface"
      else:
          echo "Controller ", index, " connected!"
          # TODO: Attach the controller
          input.controllers.add(sdl.gameControllerOpen(index))

  elif input.last_number_of_controllers > sdl.numJoysticks():
      echo "Controller dissconnected!"
      input.last_number_of_controllers = sdl.numJoysticks()

  # GetAttached -> returns if a gamecontroller is still attached, could be useful for disconnection
  for c in input.controllers:
    echo sdl.gameControllerGetAttached(c)

proc processEvent* (ev: var sdl.Event)=
  case ev.kind:
  of sdl.KeyDown :
      if ev.key.repeat > 0: return
      let key = getKeyInRange ev.key.keysym.sym.cint

      if input.keyMap.hasKey(key) == false:
          input.keyMap.add(key, newKeyState(1))
      else:
          input.keyMap[key] = newKeyState(1, 0)

  of sdl.KeyUp:
      if ev.key.repeat > 0: return
      let key = getKeyInRange ev.key.keysym.sym.cint

      if input.keyMap.hasKey(key) == false:
          input.keyMap.add(key, newKeyState(1))
      else:
          input.keyMap[key] = newKeyState(0, 1)

  of sdl.MouseButtonDown:
      case ev.button.button:
      of sdl.BUTTON_LEFT:
          input.mouse_left.state = 1

      of sdl.BUTTON_RIGHT:
          input.mouse_right.state = 1

      of sdl.BUTTON_MIDDLE:
          discard
      else:
          discard

  of sdl.MouseButtonUp:
      case ev.button.button:
      of sdl.BUTTON_LEFT:
          input.mouse_left.state = 0
          input.mouse_left.last = 1

      of sdl.BUTTON_RIGHT:
          input.mouse_right.state = 0
          input.mouse_right.last = 1

      of sdl.BUTTON_MIDDLE:
          discard
      else:
          discard

  # of sdl.JoystickAx
      # echo "Wat"
  
  else:
    discard

include private/key_map

import
  glfw/wrapper,
  platform,
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

var input = InputManager(
  mouseX: 0, mouseY: 0,
  lastMouseX: 0, lastMouseY: 0,
  lastNumberOfControllers: 0,
  mouseLeft: MouseState(state : 0, last : 0),
  mouseRight: MouseState(state : 0, last : 0),
  keyMap: initTable[int, KeyState]())

proc newKeyState*(state=0, last=0): KeyState=
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
  result = wrapper.getKey(platform.Window, key.int32).KeyAction == kaDown

proc isKeyUp* (input: InputManager, key: Key): bool =
    return not isKeyDown(input, key)

proc isKeyReleased* (input: InputManager, key: Key): bool=
  discard

proc isKeyPressed* (input: InputManager, key: Key): bool=
  discard

proc update* ()=
  for key, state in input.keyMap.mpairs:
      state.last = state.state

  input.mouse_left.last = input.mouse_left.state
  input.mouse_right.last = input.mouse_right.state

  # get the mouse position
  var x, y: cint
  #discard sdl.getMouseState(addr(x), addr(y))

  input.last_mouse_x = input.mouse_x
  input.last_mouse_y = input.mouse_y
  input.mouse_x = x.float
  input.mouse_y = y.float

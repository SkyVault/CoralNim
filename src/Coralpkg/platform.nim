import
  glfw/wrapper as glfw,
  opengl,
  strformat

var
  window: Window

echo "Initializing GLFW"
var winTitle = ""

type ContextSettings* = object
  minorVersion*, majorVersion*: int
  core*: bool

proc newWindow* (size: (int, int), title="", contextSettings = ContextSettings(
  minorVersion: 3,
  majorVersion: 3,
  core: true
))=

  if glfw.init() == 0:
    echo "Failed to initialize glfw"

  winTitle = "DevWindow"

  glfw.windowHint(glfw.hContextVersionMajor.int32, contextSettings.majorVersion.int32)
  glfw.windowHint(glfw.hContextVersionMinor.int32, contextSettings.minorVersion.int32)
  window = glfw.createWindow(size[0].cint, size[1].cint, "DevWindow", nil, nil)
  glfw.makeContextCurrent(window)

  loadExtensions()
  #glfw.setSwapInterval(1)

template Window*(): auto = window

proc shouldClose*(window: Window): bool =
  result = glfw.windowShouldClose(window) == 1

proc `size=`* (window: Window, size: (int, int))=
  glfw.setWindowSize(window, size[0].cint, size[1].cint)

proc size* (window: Window): (int, int)=
  var w, h: cint = 0
  glfw.getWindowSize(window, addr w, addr h)
  result = (w.int, h.int)

proc `title=`*(window: Window, title: string)=
  winTitle = title
  glfw.setWindowTitle(window, title)

proc title*(window: Window): string=
  result = winTitle

proc update* ()=
  glfw.pollEvents()
  glfw.swapBuffers(window)

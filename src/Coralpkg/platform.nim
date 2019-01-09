import
    nimgl/[opengl, glfw],
    strformat

{.pragma: glfw_lib, cdecl.}
proc glfwSetWindowSize*(window: GLFWWindow, width: int32, height: int32) {.glfw_lib, importc: "glfwSetWindowSize".}

var
  window: GLFWWindow

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

  if not glfwInit():
    echo "Failed to initialize glfw"

  winTitle = "DevWindow"

  glfwWindowHint(whContextVersionMajor, 4)
  glfwWindowHint(whContextVersionMinor, 5)
  glfwWindowHint(whOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(whOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(whResizable, GLFW_TRUE)

  # glfw.windowHint(glfw.hContextVersionMajor.int32, contextSettings.majorVersion.int32)
  # glfw.windowHint(glfw.hContextVersionMinor.int32, contextSettings.minorVersion.int32)

  window = glfwCreateWindow(1280, 720, "DevWindow", nil, nil)
  window.makeContextCurrent()

  assert glInit()
  #glfw.setSwapInterval(1)

template Window*(): auto = window

proc shouldClose*(window: GLFWWindow): bool =
  result = glfw.windowShouldClose(window)

proc `size=`* (window: GLFWWindow, size: (int, int))=
  glfwSetWindowSize(window, size[0].cint, size[1].cint)

proc size* (window: GLFWWindow): (int, int)=
  var w, h: cint = 0
  glfw.getWindowSize(window, addr w, addr h)
  result = (w.int, h.int)

proc `title=`*(window: GLFWWindow, title: string)=
  winTitle = title
  glfw.setWindowTitle(window, title)

proc title*(window: GLFWWindow): string=
  result = winTitle
#
### Returns the time in seconds
proc getTime* (): float=
  return glfw.glfwGetTime()

proc update* ()=
  glfwPollEvents()
  glfw.swapBuffers(window)

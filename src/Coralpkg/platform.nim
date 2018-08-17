import 
  sdl2/sdl,
  opengl

var 
  window: Window
  context: GLContext

template Window* (): auto = window
template Context* (): auto = context

echo "Initializing SDL2"

if sdl.init(sdl.InitVideo or sdl.InitJoystick) != 0:
    echo "Failed to initialize SDL2"
    discard readLine(stdin)
    system.quit()

# OpenGL 330 core
discard sdl.glSetAttribute(sdl.GLContextMajorVersion, 3)
discard sdl.glSetAttribute(sdl.GLContextMinorVersion, 3)

const FLAGS = sdl.WindowOpenGL

proc newWindow* (size: (int, int), title="")=
  window = sdl.createWindow(
    title,
    sdl.WindowPosUndefined,
    sdl.WindowPosUndefined,
    size[0],
    size[1],
    FLAGS.uint32)

  if window == nil:
    echo "Failed to create SDL Window"
    discard readLine(stdin)
    system.quit()

  context = glCreateContext(window)
  if context == nil:
    echo "Failed to create OpenGL Context"
    discard readLine(stdin)
    system.quit()

  # Load all of the OpenGL extension functions
  # TODO(Dustin): Check which functions we can actually use
  loadExtensions()

  if sdl.glSetSwapInterval(1) < 0:
    echo "Failed to enable VSync"

  # This is mostly just a test to make sure we can call opengl
  # functions and that the context is working
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

# Window methods
proc windowSize* (): (int, int)=
    ## Returns the size in pixels of the GLFW window
    var width, height: cint
    sdl.getWindowSize(window, addr width, addr height)
    return (width.int, height.int)

proc `windowSize=`* (size: (int, int))=
    ## Sets the size of the window
    sdl.setWindowSize(window, size[0].cint, size[1].cint)

proc windowPosition* (): (int, int)=
    ## Returns the windows position on the monitor
    var width, height: cint
    sdl.getWindowPosition(window, addr width, addr height)
    return (width.int, height.int)

proc `windowPosition=`* (pos: (int, int)) =
    sdl.setWindowPosition(window, pos[0].cint, pos[1].cint)

proc windowTitle* (): string=
    let title = sdl.getWindowTitle(window)
    return $title

proc `windowTitle=`* (title: string)=
    sdl.setWindowTitle(window, title.cstring)

proc windowVisible* (): bool =
    let flags = sdl.getWindowFlags(window)
    return (flags and sdl.WINDOW_SHOWN) == 1

proc `windowVisible=`* (visible: bool) =
    if visible: sdl.hideWindow(window)
    else: sdl.showWindow(window)

proc update* ()=
  sdl.glSwapWindow(window)

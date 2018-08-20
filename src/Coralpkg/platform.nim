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
proc `size=`* (win: Window, size: (int, int)){.inline.}=
    ## Sets the size of the window
    sdl.setWindowSize(win, size[0].cint, size[1].cint)

proc size* (win: Window): (int, int){.inline.}=
    ## Returns the size in pixels of the GLFW window
    var width, height: cint
    sdl.getWindowSize(win, addr width, addr height)
    return (width.int, height.int)

proc position* (win: Window): (int, int)=
    ## Returns the windows position on the monitor
    var width, height: cint
    sdl.getWindowPosition(win, addr width, addr height)
    return (width.int, height.int)

proc `position=`* (win: Window, pos: (int, int)) =
    sdl.setWindowPosition(win, pos[0].cint, pos[1].cint)

proc title* (win: Window): string {.inline.}=
    let title = sdl.getWindowTitle(win)
    return $title

proc `title=`*(win: Window, title: string) {.inline.}=
    sdl.setWindowTitle(win, title.cstring)

proc visible* (win: Window): bool =
    let flags = sdl.getWindowFlags(win)
    return (flags and sdl.WINDOW_SHOWN) == 1

proc `visible=`* (win: Window, visible: bool) =
    if visible: sdl.hideWindow(win)
    else: sdl.showWindow(win)

proc update* ()=
  sdl.glSwapWindow(window)

import 
    system,
    opengl,
    os,
    glfw,
    renderer,
    glfw/wrapper as glfwx

type
    Clock = ref object
        fps, delta, last, timer, last_fps: float
        ticks: int

    CoralConfig = ref object
        resizable: bool
        fullscreen: bool
        visible: bool
        fps: int

    CoralGame = ref object
        window: GLFWwindow
        config: CoralConfig
        running: bool
        targetFPS: int
        r2d: R2D
        clock: Clock
        title: string
        load*: proc()
        update*: proc()
        draw*: proc()
        destroy*:proc()
    
# CLOCK API
proc timer*         (c: Clock): float {.inline.} = c.timer
proc currentFPS*    (c: Clock): float {.inline.} = c.fps
proc dt*            (c: Clock): float {.inline.} = c.delta
proc ticks*         (c: Clock): int   {.inline.} = c.ticks

proc config* (resizable = false, fullscreen = false, visible = true, fps = 60): CoralConfig=
    CoralConfig(
        resizable: resizable,
        fullscreen: fullscreen,
        visible: visible,
        fps: fps
     )

proc newGame* (width, height: int, title: string, config: CoralConfig): CoralGame=
    ## Initializes the game object

    result = CoralGame(
        window: nil,
        config: config,
        targetFPS: config.fps,
        load: proc()=discard,
        update: proc()=discard,
        draw: proc()=discard,
        destroy: proc()=discard,
        r2d: nil,
        title: title,
        clock: Clock(
            fps: 0.0,
            delta: config.fps.float / 1000.0,
            timer: 0.0,
            last: glfwx.getTime().float,
            last_fps: glfwx.getTime().float,
            ticks: 0
        )
    )

    let succ = glfwx.init()

    if succ == 0:
        echo "ERROR INITIALIZING GLFW!!"
        echo "TODO: Make less shitty error messages"
        discard readLine(stdin)
        quit()

    # Set the OpenGL version to 330 core
    # TODO: check to see if this works
    windowHint(CONTEXT_VERSION_MAJOR, 3)
    windowHint(CONTEXT_VERSION_MINOR, 3)
    windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)
    windowHint(VISIBLE, config.visible.cint)

    swapInterval(0)

    result.window = createWindow(cint(width), cint(height), cstring(title), nil, nil)
    
    if result.window == nil:
        echo "ERROR CREATING GLFW WINDOW!!"
        echo "TODO: Make less shitty error messages"
        discard readLine(stdin)
        quit()

    makeContextCurrent(result.window)

    loadExtensions()
    glClear(
        GL_COLOR_BUFFER_BIT or 
        GL_DEPTH_BUFFER_BIT
        )

    # initialize the renderer once opengl is initialized
    result.r2d = newR2D()

proc clock* (game: CoralGame): auto = game.clock

proc run* (game: CoralGame)=
    ## This method launches the game loop and begins the rendering cycle

    game.running = true

    game.load()
    while game.running:
        glfwx.pollEvents()
        glfwx.swapBuffers(game.window)

        let wait_time = 1.0 / game.targetFPS.float
        let now = getTime().float
        let curr_time = (now - game.clock.last)
        # let durr = 1000.0 * (wait_time - curr_time) + 0.5

        game.clock.delta = curr_time
        game.clock.last = now

        game.clock.fps =
            if game.clock.delta != 0.0:
                1.0 / game.clock.delta
            else:
                0.0

        # if durr > 0:
            # os.sleep(durr.int)

        game.running = 
            if glfwx.windowShouldClose(game.window) == 0:
                true
            else:
                false
        
        game.update()
        game.draw()

        game.clock.ticks += 1
        game.clock.timer += game.clock.delta

    game.destroy()

# Window functions
proc windowSize* (self: CoralGame): (int, int)=
    ## Returns the size in pixels of the GLFW window
    var width, height: cint
    getWindowSize(self.window, addr width, addr height)
    return (width.int, height.int)

proc `windowSize=`*(self: CoralGame, width, height: int)=
    ## Sets the size of the window
    setWindowSize(self.window, width.cint, height.cint)

proc windowPosition* (self: CoralGame): (int, int)=
    ## Returns the windows position on the monitor
    var width, height: cint
    getWindowPos(self.window, addr width, addr height)
    return (width.int, height.int)

proc `windowPosition=`* (self: CoralGame, x, y: int) =
    setWindowPos(self.window, x.cint, y.cint)

proc windowTitle* (self: CoralGame): string=
    return self.title 

proc `windowTitle=`* (self: CoralGame, title: string)=
    self.title = title
    setWindowTitle(self.window, title.cstring)

proc windowVisible* (self: CoralGame): bool =
    return
        if getWindowAttrib(self.window, VISIBLE) == 0:
            false
        else:
            true
    
proc `windowVisible=`* (self: CoralGame, visible: bool) =
    if visible: hideWindow(self.window)
    else: showWindow(self.window)
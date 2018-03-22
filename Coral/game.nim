import 
    system,
    opengl,
    os,
    glfw,
    renderer,
    tables,
    graphics,
    glfw/wrapper as glfwx

type
    CoralClock = ref object
        fps, delta, last, timer, last_fps: float
        ticks: int

    # Input handler
    CoralKey = ref object
        state*, last*: int

    CoralInputManager = ref object
        mouse_x, mouse_y: float64
        mouse_dx, mouse_dy: float
        last_mouse_x, last_mouse_y: float

        the_first: bool
        the_block: bool

        last_mouse_left_state, curr_mouse_left_state: bool
        last_mouse_right_state, curr_mouse_right_state: bool
        keyMap: Table[cint, CoralKey]

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
        clock: CoralClock
        input: CoralInputManager
        title: string
        load*: proc()
        update*: proc()
        draw*: proc()
        destroy*:proc()
    
# CLOCK API
proc timer*         (c: CoralClock): float {.inline.} = c.timer
proc currentFPS*    (c: CoralClock): float {.inline.} = c.fps
proc dt*            (c: CoralClock): float {.inline.} = c.delta
proc ticks*         (c: CoralClock): int   {.inline.} = c.ticks

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
        clock: CoralClock(
            fps: 0.0,
            delta: config.fps.float / 1000.0,
            timer: 0.0,
            last: glfwx.getTime().float,
            last_fps: glfwx.getTime().float,
            ticks: 0
        ),
        input: CoralInputManager(
            mouse_x: 0, mouse_y: 0,
            mouse_dx: 0, mouse_dy: 0,
            last_mouse_x: 0, last_mouse_y: 0,
            the_first: false, the_block: false,
            last_mouse_left_state: false, curr_mouse_left_state: false,
            last_mouse_right_state: false, curr_mouse_right_state: false,
            keyMap: initTable[cint, CoralKey]()
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

## Public accessor properties
proc clock* (game: CoralGame): auto = game.clock
proc input* (game: CoralGame): auto = game.input
proc r2d* (game: CoralGame):auto = game.r2d

proc newKey(): CoralKey=
    return CoralKey(state: 0, last: 0)

## Input manager functions
proc mouseX* (game: CoralGame): float= return game.input.mouse_x
proc mouseY* (game: CoralGame): float= return game.input.mouse_y

proc mousePos* (game: CoralGame): (float, float)=
    return (game.mouseX, game.mouseY)

proc mouseDeltaX* (game: CoralGame): float=return game.input.mouse_dx
proc mouseDeltaY* (game: CoralGame): float=return game.input.mouse_dy

proc isMouseLeftDown* (game: CoralGame): bool=
    var mwin = getCurrentContext()
    return mwin.getMouseButton(0) == 1

proc isMouseRightDown* (game: CoralGame): bool=
    var mwin = getCurrentContext()
    return mwin.getMouseButton(1) == 1

proc isMouseLeftPressed* (game: CoralGame): bool =
    var win = getCurrentContext()
    game.input.curr_mouse_left_state = win.getMouseButton(0) == 1
    if (game.input.curr_mouse_left_state and not game.input.last_mouse_left_state):
        return true
    return false

proc isMouseLeftReleased* (game: CoralGame): bool =
    var win = getCurrentContext()
    game.input.curr_mouse_left_state = win.getMouseButton(0) == 1
    if (not game.input.curr_mouse_left_state and game.input.last_mouse_left_state):
        return true
    return false

proc isMouseRightPressed* (game: CoralGame): bool =
    var win = getCurrentContext()
    game.input.curr_mouse_right_state = win.getMouseButton(1) == 1
    if (game.input.curr_mouse_right_state and not game.input.last_mouse_right_state):
        return true
    return false

proc isMouseRightReleased* (game: CoralGame): bool =
    var win = getCurrentContext()
    game.input.curr_mouse_right_state = win.getMouseButton(1) == 1
    if (not game.input.curr_mouse_right_state and game.input.last_mouse_right_state):
        return true
    return false

proc isKeyPressed* (game: CoralGame, key: glfw.Key): bool=
    var win = getCurrentContext()
    if (game.input.the_block): return false
    var ckey = cast[cint](key)
    if (not game.input.keyMap.contains ckey):
        var mykey = newKey()
        game.input.keyMap.add ckey, mykey
    else:
        var k = game.input.keyMap[ckey]
        k.state = getKey(game.window, ckey)
        game.input.keyMap[ckey] = k
        if (k.state == 1 and k.last == 0):
            return true
        return false

proc isKeyReleased* (game: CoralGame, key: glfw.Key): bool=
    var win = getCurrentContext()
    if (game.input.the_block): return false
    var ckey = cast[cint](key)
    if (not game.input.keyMap.contains ckey):
        var mykey = newKey()
        game.input.keyMap.add ckey, mykey
    else:
        var k = game.input.keyMap[ckey]
        k.state = getKey(game.window, ckey)
        game.input.keyMap[ckey] = k
        if (k.state == 0 and k.last == 1):
            return true
        return false

proc isKeyDown* (game: CoralGame, key: glfw.Key): bool =
    var win = getCurrentContext()
    var ckey = cast[cint](key)
    if not game.input.keyMap.contains ckey:
        var k = newKey()
        k.state = win.getKey(ckey)
        k.last = k.state
        game.input.keyMap.add ckey, k
    else:
        game.input.keyMap[ckey].state = getKey(game.window, ckey)
        return game.input.keyMap[ckey].state == 1

## Window functions
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

## Main gameloop
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

        # Update the input manager
        game.window.getCursorPos(addr game.input.mouse_x, addr game.input.mouse_y)

        for key in game.input.keyMap.pairs:
            var k = game.input.keyMap[key[0]]
            k.last = k.state
            game.input.keyMap[key[0]] = k
        if (game.input.last_mouse_x < 0 or game.input.last_mouse_y < 0):
            game.input.last_mouse_x = game.mouseX
            game.input.last_mouse_y = game.mouseY
        else:
            var mx = game.mouseX
            var my = game.mouseY
            game.input.mouse_dx = mx - game.input.last_mouse_x
            game.input.mouse_dy = my - game.input.last_mouse_y
        game.input.last_mouse_left_state  = game.input.curr_mouse_left_state
        game.input.last_mouse_right_state = game.input.curr_mouse_right_state
        game.input.the_first = false

        # Update and draw the game
        game.update()

        game.r2d.clear()
        game.r2d.begin(game.windowSize)
        game.draw()
        game.r2d.flush()

        # incrament the timers
        game.clock.ticks += 1
        game.clock.timer += game.clock.delta

    game.destroy()

# Game related functions
proc quit* (self: CoralGame)=
    self.running = false
    setWindowShouldClose(self.window, 1)

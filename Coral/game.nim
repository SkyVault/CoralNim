import 
    system,
    opengl,
    os,
    sdl2/sdl,
    tables,
    typetraits,

    audio,
    graphics,
    assets,
    renderer,
    ecs,
    gameMath

include input

const NUM_KEYCODES = 512

type
    CoralTimerState* {.pure.}= enum
        Playing,
        Paused

    CoralTimer* = ref object
        milliseconds: float
        repeat: int
        timer: float
        times_called: int
        state: CoralTimerState
        shouldDelete: bool
        callback: proc(): void

    CoralClock* = ref object
        fps, delta, last, timer, last_fps: float
        avFps, avDt: float
        fpsSamples, dtSamples: seq[float]
        ticks: int
        timers: seq[CoralTimer]

    # Input handler
    CoralKeyState* = ref object
        state*, last*: int

    CoralInputManager* = ref object
        mouse_x, mouse_y: float64
        mouse_dx, mouse_dy: float
        last_mouse_x, last_mouse_y: float

        the_first: bool
        the_block: bool

        last_mouse_left_state, curr_mouse_left_state: bool
        last_mouse_right_state, curr_mouse_right_state: bool
        keyMap: Table[int, CoralKeyState]

        # gamepadState: Table[cint, ]

    CoralConfig* = ref object
        resizable: bool
        fullscreen: bool
        visible: bool
        fps: int

    CoralGame* = ref object
        window: sdl.Window
        context: sdl.GLContext
        
        config: CoralConfig
        running: bool
        targetFPS: int
        r2d: R2D
        clock: CoralClock
        input: CoralInputManager
        audio: CoralAudioMixer
        world: CoralWorld
        assets: CoralAssetManager
        title: string
        load*: proc()
        update*: proc()
        render*: proc()
        destroy*:proc()

proc newCoralGame()

const NUM_AVERAGE_FPS_SAMPLES = 100

# CLOCK API
proc timer*         (c: CoralClock): float {.inline.} = c.timer
proc currentFPS*    (c: CoralClock): float {.inline.} = c.fps
proc dt*            (c: CoralClock): float {.inline.} = c.delta
proc ticks*         (c: CoralClock): int   {.inline.} = c.ticks
proc averageFps*    (c: CoralClock): float {.inline.} = c.avFps
proc averageDt*     (c: CoralClock): float {.inline.} = c.avDt

proc start* (timer: CoralTimer): CoralTimer{.discardable.}=
    timer.state = CoralTimerState.Playing
    return timer

proc pause* (timer: CoralTimer): CoralTimer{.discardable.}=
    timer.state = CoralTimerState.Paused
    return timer

proc delete* (timer: CoralTimer)=
    timer.shouldDelete = true    

proc reset* (timer: CoralTimer)=
    timer.timer = 0.0
    timer.times_called = 0

proc timesCalled* (timer: CoralTimer): auto= timer.times_called

proc addTimer* (clock: CoralClock, milliseconds: float, repeat = 0, callback: proc(): void): CoralTimer{.discardable.}=
    result = CoralTimer(
            milliseconds: milliseconds,
            repeat: repeat,
            callback: callback,
            timer: 0.0,
            state: CoralTimerState.Paused,
            shouldDelete: false
        )
    clock.timers.add(result) 

var lCoral : CoralGame = nil
newCoralGame()

template Coral* (): auto = 
    lCoral

proc config* (resizable = false, fullscreen = false, visible = true, fps = 60): CoralConfig=
    CoralConfig(
        resizable: resizable,
        fullscreen: fullscreen,
        visible: visible,
        fps: fps
     )

proc newCoralGame()=
    let config = config()

    lCoral = CoralGame(
        window: nil,
        config: config,
        targetFPS: config.fps,
        load: proc()=discard,
        update: proc()=discard,
        render: proc()=discard,
        destroy: proc()=discard,
        r2d: nil,
        title: "",
        clock: CoralClock(
            fps: 0.0,
            avFps: 0.0,
            avDt: 0.0,
            fpsSamples: newSeq[float](),
            dtSamples: newSeq[float](),
            delta: config.fps.float / 1000.0,
            timer: 0.0,

            #TODO: MOVE TO SDL
            last: 0.0, #getTime().float,
            last_fps: 0.0, #getTime().float,
            ticks: 0,
            timers: newSeq[CoralTimer]()
        ),
        input: CoralInputManager(
            mouse_x: 0, mouse_y: 0,
            mouse_dx: 0, mouse_dy: 0,
            last_mouse_x: 0, last_mouse_y: 0,
            the_first: false, the_block: false,
            last_mouse_left_state: false, curr_mouse_left_state: false,
            last_mouse_right_state: false, curr_mouse_right_state: false,
            keyMap: initTable[int, CoralKeyState]()
        ),
        audio: CoralAudioMixer(

        ),
        assets: CoralAssetManager(
            images: newTable[string, Image](),
            audio: newTable[string, Audio]()
        ),
        world: nil
    )

    lCoral.audio.init()

    if sdl.init(sdl.InitVideo) != 0:
        echo "ERROR INITIALIZING SDL2!!"
        echo "TODO: Make less shitty error messages"
        discard readLine(stdin)
        system.quit()

proc createGame* (self: CoralGame, width, height: int, title: string, config: CoralConfig): CoralGame{.discardable.}=
    ## Initializes the game object
    # Set the OpenGL version to 330 core
    # TODO: check to see if this works

    # windowHint(CONTEXT_VERSION_MAJOR, 3)
    # windowHint(CONTEXT_VERSION_MINOR, 3)
    # windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)
    # windowHint(VISIBLE, config.visible.cint)

    discard sdl.glSetAttribute(sdl.GLContextMajorVersion, 3)
    discard sdl.glSetAttribute(sdl.GLContextMinorVersion, 3)
    # discard sdl.glSetAttribute(sdl.GLContextProfileMast, sdl.GLContextProfileCore)

    var flags = sdl.WindowOpenGL

    if config.visible:      flags = flags or sdl.WindowShown
    if config.resizable:    flags = flags or sdl.WindowResizable
    if config.fullscreen:   flags = flags or sdl.WindowFullscreen

    lCoral.window = sdl.createWindow(
        title,
        sdl.WindowPosUndefined,
        sdl.WindowPosUndefined,
        width,
        height,

        flags.uint32
    )

    lCoral.config = config
    
    if lCoral.window == nil:
        echo "ERROR CREATING GLFW WINDOW!!"
        echo "TODO: Make less shitty error messages"
        discard readLine(stdin)
        system.quit()

    # Creating the GL Context
    lCoral.context = glCreateContext(lCoral.window)
    if lCoral.context == nil:
        echo "Could not create context"
        echo "TODO: Make less shitty error messages"
        discard readLine(stdin)
        system.quit()

    loadExtensions()

    # Try to enable VSync
    if sdl.glSetSwapInterval(1) < 0:
        echo "Could not enable Vsync"

    glClear(
        GL_COLOR_BUFFER_BIT or 
        GL_DEPTH_BUFFER_BIT
        )

    # initialize the renderer once opengl is initialized
    # let draw_instanced = 
    #     extensionSupported("GL_ARB_instanced_arrays") == 1 or  
    #     extensionSupported("GL_EXT_instanced_arrays") == 1 

    lCoral.r2d = newR2D(
        draw_instanced = false# draw_instanced
    )
    return lCoral

## Public accessor properties
proc clock* (game: CoralGame): auto = game.clock
proc input* (game: CoralGame): auto = game.input
proc r2d* (game: CoralGame):auto = 
    assert(game.r2d != nil, "[ERROR]:: Game needs to be created before using the renderer")
    return game.r2d

proc audio* (game: CoralGame):auto = game.audio

proc world* (c: CoralGame): CoralWorld=
    if c.world == nil:
        c.world = newCoralWorld()
    return c.world

proc assets* (c: CoralGame): CoralAssetManager=
    return c.assets


proc newKeyState(state = 0, last = 0): CoralKeyState=
    return CoralKeyState(state: state, last: last)

## Input manager functions

## Game pad
# proc IsGamepadConnected* (game: CoralGame, which = 0): bool=
#     return 
#         joystickPresent(which.cint) == 1

# proc IsButtonDown(game: CoralGame )

proc mouseX* (game: CoralGame): float= return game.input.mouse_x
proc mouseY* (game: CoralGame): float= return game.input.mouse_y

proc mousePos* (game: CoralGame): (float, float)=
    return (game.mouseX, game.mouseY)

proc mouseDeltaX* (game: CoralGame): float=return game.input.mouse_dx
proc mouseDeltaY* (game: CoralGame): float=return game.input.mouse_dy

proc getKeyInRange(key: cint): int=
    if key > (1 shl 30):
        return ((sdl.K_Delete.int) + (key - (1 shl 30))).int
    else:
        return key.int 

# proc isMouseLeftDown* (game: CoralGame): bool=
#     var mwin = getCurrentContext()
#     return mwin.getMouseButton(0) == 1

# proc isMouseRightDown* (game: CoralGame): bool=
#     var mwin = getCurrentContext()
#     return mwin.getMouseButton(1) == 1

# proc isMouseLeftPressed* (game: CoralGame): bool =
#     var win = getCurrentContext()
#     game.input.curr_mouse_left_state = win.getMouseButton(0) == 1
#     if (game.input.curr_mouse_left_state and not game.input.last_mouse_left_state):
#         return true
#     return false

# proc isMouseLeftReleased* (game: CoralGame): bool =
#     var win = getCurrentContext()
#     game.input.curr_mouse_left_state = win.getMouseButton(0) == 1
#     if (not game.input.curr_mouse_left_state and game.input.last_mouse_left_state):
#         return true
#     return false

# proc isMouseRightPressed* (game: CoralGame): bool =
#     var win = getCurrentContext()
#     game.input.curr_mouse_right_state = win.getMouseButton(1) == 1
#     if (game.input.curr_mouse_right_state and not game.input.last_mouse_right_state):
#         return true
#     return false

# proc isMouseRightReleased* (game: CoralGame): bool =
#     var win = getCurrentContext()
#     game.input.curr_mouse_right_state = win.getMouseButton(1) == 1
#     if (not game.input.curr_mouse_right_state and game.input.last_mouse_right_state):
#         return true
#     return false

# proc isKeyPressed* (game: CoralGame, key: CoralKey): bool=
#     if (game.input.the_block): return false
#     var ckey = cast[cint](key)
#     if (not game.input.keyMap.contains ckey):
#         var mykey = newKey()
#         game.input.keyMap.add ckey, mykey
#     else:
#         var k = game.input.keyMap[ckey]
#         k.state = getKey(game.window, ckey)
#         game.input.keyMap[ckey] = k
#         if (k.state == 1 and k.last == 0):
#             return true
#         return false

# proc isKeyReleased* (game: CoralGame, key: CoralKey): bool=
#     if (game.input.the_block): return false
#     var ckey = cast[cint](key)
#     if (not game.input.keyMap.contains ckey):
#         var mykey = newKey()
#         game.input.keyMap.add ckey, mykey
#     else:
#         var k = game.input.keyMap[ckey]
#         k.state = getKey(game.window, ckey)
#         game.input.keyMap[ckey] = k
#         if (k.state == 0 and k.last == 1):
#             return true
#         return false

proc isKeyDown* (game: CoralGame, key: Keycode): bool =
    var ckey = getKeyInRange(key.cint)
    if not game.input.keyMap.contains ckey:
        return false
    else:
        return
            game.input.keyMap[ckey].state == 1

# ## Window functions
proc windowSize* (self: CoralGame): (int, int)=
    ## Returns the size in pixels of the GLFW window
    var width, height: cint
    sdl.getWindowSize(self.window, addr width, addr height)
    return (width.int, height.int)

proc `windowSize=`*(self: CoralGame, width, height: int)=
    ## Sets the size of the window
    sdl.setWindowSize(self.window, width.cint, height.cint)

# proc windowPosition* (self: CoralGame): (int, int)=
#     ## Returns the windows position on the monitor
#     var width, height: cint
#     getWindowPos(self.window, addr width, addr height)
#     return (width.int, height.int)

# proc `windowPosition=`* (self: CoralGame, x, y: int) =
#     setWindowPos(self.window, x.cint, y.cint)

# proc windowTitle* (self: CoralGame): string=
#     return self.title 

# proc `windowTitle=`* (self: CoralGame, title: string)=
#     self.title = title
#     setWindowTitle(self.window, title.cstring)

# proc windowVisible* (self: CoralGame): bool =
#     return
#         if getWindowAttrib(self.window, VISIBLE) == 0:
#             false
#         else:
#             true
    
# proc `windowVisible=`* (self: CoralGame, visible: bool) =
#     if visible: hideWindow(self.window)
#     else: showWindow(self.window)

## Main gameloop
proc run* (game: CoralGame)=
    ## This method launches the game loop and begins the rendering cycle

    game.running = true
    game.load()

    var ev: sdl.Event

    while game.running:
        # echo cast[int](Keycode.K_Left) - 0x40000000

        while sdl.pollEvent(addr(ev)) != 0:
            case ev.kind:
                of sdl.Quit:
                    game.running = false

                of sdl.KeyDown:
                    let key = getKeyInRange ev.key.keysym.sym.cint

                    if game.input.keyMap.hasKey(key) == false:
                        game.input.keyMap.add(key, newKeyState(1)) 
                    else:
                        let state = game.input.keyMap[key]
                        game.input.keyMap[key] = newKeyState(
                            1,
                            state.state
                        )

                of sdl.KeyUp:
                    let key = getKeyInRange ev.key.keysym.sym.cint

                    if game.input.keyMap.hasKey(key) == false:
                        game.input.keyMap.add(key, newKeyState(1)) 
                    else:
                        let state = game.input.keyMap[key]
                        game.input.keyMap[key] = newKeyState(
                            0,
                            state.state
                        )
                
                else:
                    discard

        game.update()

        game.r2d.viewport = game.windowSize
        # game.r2d.clear()
        # if game.world.isNil == false:
        #     game.world.draw()

        # game.render()
        # game.r2d.flush()

        # pollEvents()

        # # let wait_time = 1.0 / game.targetFPS.float
        # let now = getTime().float
        # let curr_time = (now - game.clock.last)
        # # let durr = 1000.0 * (wait_time - curr_time) + 0.5

        # game.clock.delta = curr_time
        # game.clock.last = now

        # game.clock.fps =
        #     if game.clock.delta != 0.0:
        #         1.0 / game.clock.delta
        #     else:
        #         0.0

        # if game.clock.ticks == 0:
        #     game.clock.avFps = game.clock.fps
        #     game.clock.avDt = game.clock.dt
        
        # # Average out the fps
        # if game.clock.fpsSamples.len < NUM_AVERAGE_FPS_SAMPLES:
        #     game.clock.fpsSamples.add game.clock.fps
        # else:
        #     let len = game.clock.fpsSamples.len
        #     var sumation = 0.0
        #     for s in game.clock.fpsSamples:
        #         sumation += s
        #     game.clock.avFps = sumation / (len.float)
        #     game.clock.fpsSamples.setLen(0)

        # # Average out the delta time
        # if game.clock.dtSamples.len < NUM_AVERAGE_FPS_SAMPLES:
        #     game.clock.dtSamples.add game.clock.dt
        # else:
        #     let len = game.clock.dtSamples.len
        #     var sumation = 0.0
        #     for d in game.clock.dtSamples:
        #         sumation += d
        #     game.clock.avDt = sumation / (len.float)
        #     game.clock.dtSamples.setLen(0)

        # game.running = 
        #     if windowShouldClose(game.window) == 0:
        #         true
        #     else:
        #         false

        # # Update the input manager
        # game.window.getCursorPos(addr game.input.mouse_x, addr game.input.mouse_y)

        # for key in game.input.keyMap.pairs:
        #     var k = game.input.keyMap[key[0]]
        #     k.last = k.state
        #     game.input.keyMap[key[0]] = k
        # if (game.input.last_mouse_x < 0 or game.input.last_mouse_y < 0):
        #     game.input.last_mouse_x = game.mouseX
        #     game.input.last_mouse_y = game.mouseY
        # else:
        #     var mx = game.mouseX
        #     var my = game.mouseY
        #     game.input.mouse_dx = mx - game.input.last_mouse_x
        #     game.input.mouse_dy = my - game.input.last_mouse_y
        # game.input.last_mouse_left_state  = game.input.curr_mouse_left_state
        # game.input.last_mouse_right_state = game.input.curr_mouse_right_state
        # game.input.the_first = false

        # # Update and draw the game
        # if game.world.isNil == false:
        #     game.world.update()
        # game.update()

        # game.r2d.viewport = game.windowSize
        # game.r2d.clear()
        # if game.world.isNil == false:
        #     game.world.draw()

        # game.render()
        # game.r2d.flush()

        # # incrament the timers
        # game.clock.ticks += 1
        # game.clock.timer += game.clock.delta

        # # Handle timers
        # for timer in game.clock.timers:
        #     if timer.state == CoralTimerState.Paused: continue

        #     timer.timer += game.clock.dt
        #     if (timer.timer * 1000.0) > timer.milliseconds:
        #         timer.times_called += 1
        #         timer.callback()
        #         timer.timer = 0
        
        # for i in countdown(game.clock.timers.len - 1, 0):
        #     let timer = game.clock.timers[i]
        #     if timer.repeat > 0 or timer.shouldDelete:
        #         if timer.times_called >= timer.repeat:
        #             game.clock.timers.delete(i)

        # swapBuffers(game.window)
    
    game.audio.destroy()
    game.destroy()

# Game related functions
proc quit* (self: CoralGame)=
    self.running = false
    # setWindowShouldClose(self.window, 1)

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

# const NUM_KEYCODES = 512
const NUM_AVERAGE_FPS_SAMPLES = 100
# const DEFUALT_NUMBER_OF_CONTROLLERS = 4

type
    TimerState* {.pure.}= enum
        Playing,
        Paused

    Timer* = ref object
        milliseconds: float
        repeat: int
        timer: float
        times_called: int
        state: TimerState
        shouldDelete: bool
        callback: proc(): void

    Clock* = ref object
        fps, delta, last, timer, last_fps: float
        avFps, avDt: float
        fpsSamples, dtSamples: seq[float]
        ticks: int
        timers: seq[Timer]

    # Input handler
    KeyState* = ref object of RootObj
        state*, last*: int

    # Mouse handler
    MouseState*  = ref object of KeyState
    ButtonState* = ref object of KeyState

    ControllerState* = ref object
        A, B, X, Y: ButtonState
        Start, Select: ButtonState
        LTrigger, RTrigger, LShoulder, RShoulder: ButtonState 

    InputManager* = ref object
        mouse_x, mouse_y: float64
        last_mouse_x, last_mouse_y: float

        last_number_of_controllers: int

        mouse_left, mouse_right: MouseState

        keyMap: Table[int, KeyState]

        controllers: seq[sdl.GameController]

        # gamepadState: Table[cint, ]

    Scene* = ref object of RootObj

    Config* = ref object
        resizable: bool
        fullscreen: bool
        visible: bool
        fps: int

    CoralGame* = ref object
        window: sdl.Window
        context: sdl.GLContext

        sceneStack: seq[Scene]
        
        config: Config
        running: bool
        targetFPS: int
        r2d: R2D
        clock: Clock
        input: InputManager
        audio: AudioMixer
        world: World
        assets: AssetManager
        title: string
        load*: proc()
        update*: proc()
        draw*: proc()
        destroy*:proc()

method load(scene: Scene) {.base.} = discard
method draw(scene: Scene) {.base.} = discard
method update(scene: Scene) {.base.} = discard
method destroy(scene: Scene) {.base.} = discard

proc currentScene* (game: CoralGame): Scene=
    result = if game.sceneStack.len() == 0:
                nil
            else:
                game.sceneStack[game.sceneStack.len() - 1]

proc newCoralGame()

# CLOCK API
proc timer*         (c: Clock): float {.inline.} = c.timer
proc currentFPS*    (c: Clock): float {.inline.} = c.fps
proc dt*            (c: Clock): float {.inline.} = c.delta
proc ticks*         (c: Clock): int   {.inline.} = c.ticks
proc averageFps*    (c: Clock): float {.inline.} = c.avFps
proc averageDt*     (c: Clock): float {.inline.} = c.avDt

proc start* (timer: Timer): Timer{.discardable.}=
    timer.state = TimerState.Playing
    return timer

proc pause* (timer: Timer): Timer{.discardable.}=
    timer.state = TimerState.Paused
    return timer

proc delete* (timer: Timer)=
    timer.shouldDelete = true    

proc reset* (timer: Timer)=
    timer.timer = 0.0
    timer.times_called = 0

proc timesCalled* (timer: Timer): auto= timer.times_called

proc addTimer* (clock: Clock, milliseconds: float, repeat = 0, callback: proc(): void): Timer{.discardable.}=
    result = Timer(
            milliseconds: milliseconds,
            repeat: repeat,
            callback: callback,
            timer: 0.0,
            state: TimerState.Paused,
            shouldDelete: false
        )
    clock.timers.add(result) 

var lCoral : CoralGame = nil
newCoralGame()

template Coral* (): auto = 
    lCoral

proc config* (resizable = false, fullscreen = false, visible = true, fps = 60): Config=
    Config(
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

        sceneStack: newSeq[Scene](),

        load: proc()=discard,
        update: proc()=discard,
        draw: proc()=discard,
        destroy: proc()=discard,
        r2d: nil,
        title: "",
        clock: Clock(
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
            timers: newSeq[Timer]()
        ),
        input: InputManager(
            mouse_x: 0, mouse_y: 0,
            last_mouse_x: 0, last_mouse_y: 0,

            last_number_of_controllers: 0,

            mouse_left: MouseState(state : 0, last : 0),
            mouse_right: MouseState(state : 0, last : 0),
            keyMap: initTable[int, KeyState](),

            controllers: newSeq[sdl.GameController]()
        ),
        audio: AudioMixer(

        ),
        assets: AssetManager(
            images: newTable[string, Image](),
            audio: newTable[string, Audio]()
        ),
        world: nil
    )

    lCoral.audio.init()

    if sdl.init(sdl.InitVideo or sdl.InitJoystick) != 0:
        echo "ERROR INITIALIZING SDL2!!"
        echo "TODO: Make less shitty error messages"
        discard readLine(stdin)
        system.quit()

proc createGame* (self: CoralGame, width, height: int, title: string, config: Config = config()): CoralGame{.discardable.}=
    ## Initializes the game object
    # Set the OpenGL version to 330 core
    # TODO: check to see if this works

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

proc world* (c: CoralGame): World=
    if c.world == nil:
        c.world = newWorld()
    return c.world

proc assets* (c: CoralGame): AssetManager=
    return c.assets


proc newKeyState(state = 0, last = 0): KeyState=
    return KeyState(state: state, last: last)

## Input manager functions

## Game pad
# proc IsGamepadConnected* (game: CoralGame, which = 0): bool=
#     return 
#         joystickPresent(which.cint) == 1

proc pullControllerInfo(input: InputManager)=
    discard

# proc IsButtonDown(game: CoralGame )

proc mouseX* (game: CoralGame): float= return game.input.mouse_x
proc mouseY* (game: CoralGame): float= return game.input.mouse_y

proc mousePos* (game: CoralGame): (float, float)=
    return (game.mouseX, game.mouseY)

proc mouseDeltaX* (game: CoralGame): float=return game.input.mouse_x - game.input.last_mouse_x
proc mouseDeltaY* (game: CoralGame): float=return game.input.mouse_y - game.input.last_mouse_y
proc mouseDeltaPos* (game: CoralGame): (float, float)=
    return (
        mouseDeltaX(game),
        mouseDeltaY(game)
    )

proc getKeyInRange(key: cint): int=
    if key > (1 shl 30):
        return ((sdl.K_Delete.int) + (key - (1 shl 30))).int
    else:
        return key.int 

proc isMouseLeftDown* (game: CoralGame): bool=
    return game.input.mouse_left.state == 1

proc isMouseLeftUp* (game: CoralGame): bool=
    return not isMouseLeftDown(game)

proc isMouseRightDown* (game: CoralGame): bool=
    return game.input.mouse_right.state == 1

proc isMouseRightUp* (game: CoralGame): bool=
    return not isMouseRightDown(game)

proc isMouseLeftPressed* (game: CoralGame): bool =
    result =
        game.input.mouse_left.state == 1 and
        game.input.mouse_left.last == 0

proc isMouseLeftReleased* (game: CoralGame): bool =
    result =
        game.input.mouse_left.state == 0 and
        game.input.mouse_left.last == 1

proc isMouseRightPressed* (game: CoralGame): bool =
    result =
        game.input.mouse_right.state == 1 and
        game.input.mouse_right.last == 0

proc isMouseRightReleased* (game: CoralGame): bool =
    result =
        game.input.mouse_right.state == 0 and
        game.input.mouse_right.last == 1

proc isKeyDown* (game: CoralGame, key: Key): bool =
    var ckey = getKeyInRange(key.cint)
    if not game.input.keyMap.contains ckey:
        return false
    else:
        return
            game.input.keyMap[ckey].state == 1

proc isKeyUp* (game: CoralGame, key: Key): bool =
    return not isKeyDown(game, key)

proc isKeyReleased* (game: CoralGame, key: Key): bool=
    var ckey = getKeyInRange(key.cint)
    if not game.input.keyMap.contains ckey:
        return false
    else:
        let state = game.input.keyMap[ckey]
        result =
            state.state == 0 and 
            state.last  == 1

proc isKeyPressed* (game: CoralGame, key: Key): bool=
    var ckey = getKeyInRange(key.cint)
    if not game.input.keyMap.contains ckey:
        return false
    else:
        let state = game.input.keyMap[ckey]
        result =
            state.state == 1 and 
            state.last  == 0

# ## Window functions
proc windowSize* (self: CoralGame): (int, int)=
    ## Returns the size in pixels of the GLFW window
    var width, height: cint
    sdl.getWindowSize(self.window, addr width, addr height)
    return (width.int, height.int)

proc `windowSize=`*(self: CoralGame, width, height: int)=
    ## Sets the size of the window
    sdl.setWindowSize(self.window, width.cint, height.cint)

proc windowPosition* (self: CoralGame): (int, int)=
    ## Returns the windows position on the monitor
    var width, height: cint
    sdl.getWindowPosition(self.window, addr width, addr height)
    return (width.int, height.int)

proc `windowPosition=`* (self: CoralGame, pos: (int, int)) =
    sdl.setWindowPosition(self.window, pos[0].cint, pos[1].cint)

proc windowTitle* (self: CoralGame): string=
    let title = sdl.getWindowTitle(self.window)
    return $title

proc `windowTitle=`* (self: CoralGame, title: string)=
    sdl.setWindowTitle(self.window, title.cstring)

proc windowVisible* (self: CoralGame): bool =
    let flags = sdl.getWindowFlags(self.window)
    return (flags and sdl.WINDOW_SHOWN) == 1

proc `windowVisible=`* (self: CoralGame, visible: bool) =
    if visible: sdl.hideWindow(self.window)
    else: sdl.showWindow(self.window)

proc pushScene* (self: CoralGame, scene: Scene): auto {.discardable.}=
    result = scene
    scene.load()
    self.sceneStack.add scene

proc popScene* (self: CoralGame): auto {.discardable.}=
    result = self.currentScene()

    if result != nil:
        result.destroy()
        self.sceneStack.delete(self.sceneStack.len() - 1)

proc gotoScene* (self: CoralGame, scene: Scene): auto {.discardable.}=
    self.popScene()
    result = self.pushScene(scene)

## Main gameloop
proc run* (game: CoralGame)=
    ## This method launches the game loop and begins the rendering cycle

    game.running = true
    game.load()

    var ev: sdl.Event

    while game.running:
        for key, state in game.input.keyMap.mpairs:
            state.last = state.state

        game.input.mouse_left.last = game.input.mouse_left.state
        game.input.mouse_right.last = game.input.mouse_right.state

        # get the mouse position
        var x, y: cint
        discard sdl.getMouseState(addr(x), addr(y))

        game.input.last_mouse_x = game.input.mouse_x
        game.input.last_mouse_y = game.input.mouse_y
        game.input.mouse_x = x.float
        game.input.mouse_y = y.float

        if game.input.last_number_of_controllers < sdl.numJoysticks():
            game.input.last_number_of_controllers = sdl.numJoysticks()

            let index = game.input.controllers.len
            if not sdl.isGameController(index):
                echo "Unsupported controller interface"
            else:
                echo "Controller ", index, " connected!"
                # TODO: Attach the controller
                game.input.controllers.add(sdl.gameControllerOpen(index))

        elif game.input.last_number_of_controllers > sdl.numJoysticks():
            echo "Controller dissconnected!"
            game.input.last_number_of_controllers = sdl.numJoysticks()

        # GetAttached -> returns if a gamecontroller is still attached, could be useful for disconnection

        for c in game.input.controllers:
            echo sdl.gameControllerGetAttached(c)

        while sdl.pollEvent(addr(ev)) != 0:
            case ev.kind:
                of sdl.Quit:
                    game.running = false

                of sdl.KeyDown :
                    if ev.key.repeat > 0: continue
                    let key = getKeyInRange ev.key.keysym.sym.cint

                    if game.input.keyMap.hasKey(key) == false:
                        game.input.keyMap.add(key, newKeyState(1)) 
                    else:
                        game.input.keyMap[key] = newKeyState(1, 0)

                of sdl.KeyUp:
                    if ev.key.repeat > 0: continue
                    let key = getKeyInRange ev.key.keysym.sym.cint

                    if game.input.keyMap.hasKey(key) == false:
                        game.input.keyMap.add(key, newKeyState(1)) 
                    else:
                        game.input.keyMap[key] = newKeyState(0, 1)

                of sdl.MouseButtonDown:
                    case ev.button.button:
                    of sdl.BUTTON_LEFT: 
                        game.input.mouse_left.state = 1

                    of sdl.BUTTON_RIGHT:
                        game.input.mouse_right.state = 1

                    of sdl.BUTTON_MIDDLE:
                        discard
                    else:
                        discard

                of sdl.MouseButtonUp:
                    case ev.button.button:
                    of sdl.BUTTON_LEFT: 
                        game.input.mouse_left.state = 0
                        game.input.mouse_left.last = 1

                    of sdl.BUTTON_RIGHT:
                        game.input.mouse_right.state = 0
                        game.input.mouse_right.last = 1

                    of sdl.BUTTON_MIDDLE:
                        discard
                    else:
                        discard

                # of sdl.JoystickAx
                    # echo "Wat"
                
                else:
                    discard

        # Handle timing
        let now = sdl.getTicks().float
        game.clock.delta = (now - game.clock.last) / 1000.0
        game.clock.last = now

        game.clock.fps =
            if game.clock.delta != 0.0:
                1.0 / game.clock.delta
            else:
                0.0

        if game.clock.ticks == 0:
            game.clock.avFps = game.clock.fps
            game.clock.avDt = game.clock.dt
        
        # Average out the fps
        if game.clock.fpsSamples.len < NUM_AVERAGE_FPS_SAMPLES:
            game.clock.fpsSamples.add game.clock.fps
        else:
            let len = game.clock.fpsSamples.len
            var sumation = 0.0
            for s in game.clock.fpsSamples:
                sumation += s
            game.clock.avFps = sumation / (len.float)
            game.clock.fpsSamples.setLen(0)

        # Average out the delta time
        if game.clock.dtSamples.len < NUM_AVERAGE_FPS_SAMPLES:
            game.clock.dtSamples.add game.clock.dt
        else:
            let len = game.clock.dtSamples.len
            var sumation = 0.0
            for d in game.clock.dtSamples:
                sumation += d
            game.clock.avDt = sumation / (len.float)
            game.clock.dtSamples.setLen(0)

        # incrament the timers
        game.clock.ticks += 1
        game.clock.timer += game.clock.delta

        # Handle timers
        for timer in game.clock.timers:
            if timer.state == TimerState.Paused: continue

            timer.timer += game.clock.dt
            if (timer.timer * 1000.0) > timer.milliseconds:
                timer.times_called += 1
                timer.callback()
                timer.timer = 0
        
        for i in countdown(game.clock.timers.len - 1, 0):
            let timer = game.clock.timers[i]
            if timer.repeat > 0 or timer.shouldDelete:
                if timer.times_called >= timer.repeat:
                    game.clock.timers.delete(i)

        # Update and render the world

        if game.world.isNil == false:
            game.world.update()

        game.update()

        if game.currentScene() != nil:
            game.currentScene().update()

        game.r2d.viewport = game.windowSize
        game.r2d.clear()
        if game.world.isNil == false:
            game.world.draw()

        if game.currentScene() != nil:
            game.currentScene().draw()

        game.draw()
        game.r2d.flush()

        sdl.glSwapWindow(game.window)
    
    game.audio.destroy()
    game.destroy()

# Game related functions
proc quit* (self: CoralGame)=
    self.running = false
    # setWindowShouldClose(self.window, 1)

# template CoralImportAll*()=
#     import 
#         Coral/graphics,
#         Coral/renderer,
#         Coral/gameMath,
#         Coral/graphics,
#         Coral/ecs,
#         Coral/audio
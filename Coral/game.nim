import 
    system,
    opengl,
    glfw,
    glfw/wrapper as glfwx

type
    CoralConfig = ref object
        resizable: bool
        fullscreen: bool
        visible: bool

    CoralGame = ref object
        window: GLFWwindow
        config: CoralConfig
        running: bool
        load*: proc()
        update*: proc()
        draw*: proc()
        destroy*:proc()

proc config* (resizable = false, fullscreen = false, visible = true): CoralConfig=
    CoralConfig(
        resizable: resizable,
        fullscreen: fullscreen
     )

proc newGame* (width, height: int, title: string, config: CoralConfig): CoralGame=
    result = CoralGame(
        window: nil,
        config: config,
        load: proc()=discard,
        update: proc()=discard,
        draw: proc()=discard,
        destroy: proc()=discard
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

proc run* (game: CoralGame)=
    game.running = true

    game.load()
    while game.running:
        glfwx.pollEvents()
        glfwx.swapBuffers(game.window)

        game.running = 
            if glfwx.windowShouldClose(game.window) == 0:
                true
            else:
                false

        game.update()
        game.draw()
    game.destroy()
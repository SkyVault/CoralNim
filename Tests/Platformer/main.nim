import 
    ../../Coral/game,
    ../../Coral/graphics,
    ../../Coral/renderer,
    ../../Coral/tiled,
    os,
    opengl

var map: TiledMap

var buff: GLuint = 0
var vao: GLuint = 0

Coral.load = proc()=
    map = loadTiledMap getCurrentDir() & "/assets/map1.tmx"

    var vertices: array[9, GLfloat] = [
        0.0.GLfloat, -1.0, 0.0,
        -1.0, 1.0, 0.0,
        1.0, 1.0, 0.0
    ]

    glGenVertexArrays(1, addr vao)
    glBindVertexArray(vao)

    glGenBuffers(1, addr buff)
    glBindBuffer(GL_ARRAY_BUFFER, buff)
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 9, addr vertices[0], GL_STATIC_DRAW)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    glBindVertexArray(0)

Coral.update = proc()=
    if Coral.isKeyPressed CoralKey.Escape:
        Coral.quit()

Coral.render = proc()=
    Coral.windowTitle = $Coral.clock.averageFps
    Coral.r2d.drawTiledMap(map, White)

    glBindVertexArray(vao)
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, buff);
    glVertexAttribPointer(
        0.GLuint,                  
        3.GLint,                  
        cGL_FLOAT,           
        GL_FALSE,           
        0.GLsizei,                  
        cast[pointer](0)
    )

    # glColor3f(1.0, 1.0, 1.0)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    glBindVertexArray(0)

Coral.createGame(720, 720, "Hello World", config(resizable = true))
    .run()
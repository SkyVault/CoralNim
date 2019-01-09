# Coral opengl wrapper
import
  strformat,
  maths,
  typeinfo,
  typetraits

include private/color

# NOTE(Dustin): Includes nimgl/opengl
# TODO(Dustin): Find a way to work around having the image
# needing to include opengl, maybe we should have all the opengl
# related stuff over here and just have the pixel loading in the 
# image file??
include private/image

## Vertex arrays
proc newVertexArray* (shouldBind = true): GLuint=
  glGenVertexArrays(1, addr result)
  if shouldBind: glBindVertexArray(result)

proc bindVertexArray* (buffer: GLuint)=
    glBindVertexArray(buffer)

proc unBindVertexArray* ()=
  glBindVertexArray(0)

template useVertexArray* (buffer: GLuint, body: untyped)=
    bindVertexArray(buffer)
    body
    unBindVertexArray()

## Vertex buffers
proc newVertexBufferObject* [T](btype: GLenum, dimensions: uint32, attrib: uint32, data: var seq[T], dynamic = false): GLuint=
    glGenBuffers(1, addr result)
    glBindBuffer(btype, result)

    var GLType = EGL_FLOAT
    var ctype = sizeof(T)

    if T is float or T is float64 or T is int or T is int32 or T is uint or T is uint32:
      discard
    else:
      echo "Un supported type passed into newVertexBufferObject"
      ctype = sizeof(cint)

    glBufferData(
        btype,
        cast[GLsizeiptr](ctype * data.len),
        (if data.len == 0: cast[pointer](0) else: addr data[0]),
        if dynamic: GL_DYNAMIC_DRAW
        else: GL_STATIC_DRAW)

    glEnableVertexAttribArray(GLuint(attrib))

    glVertexAttribPointer(
        (GLuint)attrib,
        (GLint)dimensions,
        GLType,
        false,
        0,
        cast[pointer](0))

    glBindBuffer(btype, 0)

proc newElementBuffer* [T](indices: var seq[T]): GLuint =
  glGenBuffers(1, addr result)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(T) * indices.len, addr indices[0], GL_STATIC_DRAW)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

proc bindElementBuffer* (id: GLuint)=
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id)

proc unBindElementBuffer* ()=
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

template useElementBuffer* (id: GLuint, body: untyped)=
  bindElementBuffer(id)
  body
  unBindElementBuffer()

proc bindVertexBufferObject* (id: GLuint, btype: GLenum)=
   glBindBuffer(btype, id)

proc unBindVertexBufferObject* (btype: GLenum)=
   glBindBuffer(btype, 0)

template useVertexBufferObject* (id: GLuint, btype: GLenum, body: untyped)=
    bindVertexBufferObject(id, btype)
    body
    unBindVertexBufferObject(btype)

## Shaders
proc loadShaderFromString* (stype: GLenum, code: string): GLuint=
    result = glCreateShader(stype)

    # NOTE(Dustin): We need to look into this and see 
    # if this leaks memory, if it does the garbage collector
    # will probably take care of it, but idk
    var cstr = code.cstring 
    glShaderSource(result, 1, cstr.addr, nil)
    glCompileShader(result)

    var
        res: GLint = 0
        log_len: GLint = 0

    glGetShaderiv(result, GL_COMPILE_STATUS, addr res)
    glGetShaderiv(result, GL_INFO_LOG_LENGTH, addr log_len)

    if log_len > 0:
        var log: cstring = cast[cstring](alloc(log_len + 1))
        glGetShaderInfoLog(
            result,
            (GLsizei)log_len,
            nil,
            log)
      
        let shaderStr =
          case stype:
           of GL_VERTEX_SHADER:
             "GL_VERTEX_SHADER"
           of GL_FRAGMENT_SHADER:
             "GL_FRAGMENT_SHADER"
           of GL_GEOMETRY_SHADER:
             "GL_GEOMETRY_SHADER"
           else: ""

        echo &"{shaderStr}::ERROR: {log}"
        dealloc(log)

proc newShaderProgram* (vertex = 0.GLuint, fragment = 0.GLuint, geometry = 0.GLuint): GLuint=
  result = glCreateProgram()

  if vertex != 0: glAttachShader(result, vertex)
  if fragment != 0: glAttachShader(result, fragment)
  if geometry != 0: glAttachShader(result, geometry)
  glLinkProgram(result)

  var
      res: GLint = 0
      log_len: GLint = 0

  glGetProgramiv(result, GL_LINK_STATUS, addr res)
  glGetProgramiv(result, GL_INFO_LOG_LENGTH, addr log_len)
  if log_len > 0:
    var log: cstring = cast[cstring](alloc(log_len + 1))
    glGetProgramInfoLog(result, (GLsizei)log_len, nil, log)
    echo &"PROGRAM::ERROR: {log}"
    dealloc(log) # might not need to with garbage collection

proc bindShaderProgram* (prog: GLuint)=
  glUseProgram(prog)

proc unBindShaderProgram* ()=
  glUseProgram(0)

template useShaderProgram* (prog: GLuint, body: untyped)=
  bindShaderProgram(prog)
  body
  unBindShaderProgram()

##
## Uniforms
##

proc getUniformLoc* (prog: GLuint, id: string): auto=
  result = glGetUniformLocation(prog, id)

template `%`* (prog: GLuint, id: string): GLint=
  result = getUniformLoc(prog, id)

proc setUniform* (id: GLint, i: int)= glUniform1i(id, i.cint)
proc setUniform* (id: GLint, b: bool)= glUniform1i(id, (if b: 1 else: 0))
proc setUniform* (id: GLint, f: float)= glUniform1f(id, f)
proc setUniform* (id: GLint, x, y: float)= glUniform2f(id, x, y)
proc setUniform* (id: GLint, x, y, z: float)= glUniform3f(id, x, y, z)
proc setUniform* (id: GLint, x, y, z, w: float)= glUniform4f(id, x, y, z, w)

proc setUniform* (id: GLint, v3: Vec3)=
  setUniform(id, v3.x, v3.y, v3.z)

proc setUniform* (id: GLint, v3: Vec3, w: float)=
  setUniform(id, v3.x, v3.y, v3.z, w)

proc setUniform* (id: GLint, m: var array[16, float32])=
  glUniformMatrix4fv(id, 1, false, addr m[0])

proc setUniform* (id: GLint, m: var Mat4)=
  # TODO(Dustin): Fix the matrix maths so that we
  # dont need to transpose it
  glUniformMatrix4fv(id, 1, true, addr m.m[0])

## GL functions
proc clearColorBuffer* (clearColor=(0.0, 0.0, 0.0, 1.0))=
  glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3])
  glClear(GL_COLOR_BUFFER_BIT)

proc clearDepthBuffer* (clearColor=(0.0, 0.0, 0.0, 1.0))=
  glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3])
  glClear(GL_DEPTH_BUFFER_BIT)

proc clearStencilBuffer* (clearColor=(0.0, 0.0, 0.0, 1.0))=
  glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3])
  glClear(GL_STENCIL_BUFFER_BIT)

proc clearColorAndDepthBuffers* (clearColor=(0.0, 0.0, 0.0, 1.0))=
  glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3])
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc clearColorDepthAndStencilBuffers* (clearColor=(0.0, 0.0, 0.0, 1.0))=
  glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3])
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

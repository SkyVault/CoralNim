import 
    graphics,
    opengl,
    tables,
    gameMath as NimMath,
    assets,
    math,
    strutils,
    tiled,
    algorithm

include shaders

## NOTES ABOUT BATCHING
#[
    The renderer does support batching the sprites and instancing them, several problems arise
    when I do this though, on of which is that I cant do primitives like I would want. Second
    the batch isn't as fast as I imagined. Finally, with batching you cant play with different 
    blend modes. So in the end, unless I want something very complex, its not going to work for
    now.
]#

type 
    BufferTypes* = enum
        BT_ARRAY_BUFFER,
        BT_ELEMENT_ARRAY_BUFFER

proc getGLBufferType(bttype: BufferTypes): GLenum=
    return 
        case bttype:
        of BT_ARRAY_BUFFER: GL_ARRAY_BUFFER
        of BT_ELEMENT_ARRAY_BUFFER: GL_ELEMENT_ARRAY_BUFFER
        else: GL_ARRAY_BUFFER

proc makeVao* (should_bind = true): uint32=
    result = 0'u32
    glGenVertexArrays(1, addr result)
    if should_bind: glBindVertexArray(result)

proc makeVbo* (buffer_type: BufferTypes, dimensions: uint32, attrib: uint32, buffer: var seq[float32], dynamic = false): uint32=
    result = 0
    let the_type = getGLBufferType buffer_type
    glGenBuffers(1, addr result)
    glBindBuffer(the_type, result)

    glBufferData(
        the_type,
        cast[GLsizeiptr](sizeof(float32) * buffer.len),
        addr buffer[0],
        if dynamic: GL_DYNAMIC_DRAW
        else: GL_STATIC_DRAW)

    glEnableVertexAttribArray(attrib)
    glVertexAttribPointer(
        (GLuint)attrib,
        (GLint)dimensions,
        cGL_FLOAT,
        GL_FALSE,
        GLsizei(0),
        nil
    )
    glBindBuffer(the_type, 0)

const RECT_VERTICES = @[
    -0.5'f32, 0.5,
    -0.5, -0.5,
    0.5, -0.5,
    0.5, 0.5
]

const RECT_INDICES = @[
    0'u8, 1, 2, 2, 3, 0
]

type 
    RotationMode* {.pure.} = enum
        Degrees,
        Radians

    BlendMode* {.pure.} = enum
        Alpha,
        Additive

    Drawable* = ref object of RootObj
      image: Image
      region: Region
      x, y, width, height: float
      rotation: float
      diffuse: Color
      layer: float

    DrawablePrimitive* = ref object of RootObj
        x, y, rotation: float
        color: Color
        layer: float

    DrawableRectanglePrimitive* = ref object of DrawablePrimitive
        width, height: float

    DrawableLineRectanglePrimitive* = ref object of DrawablePrimitive
        width, height: float

    DrawableCirclePrimitive* = ref object of DrawablePrimitive
        radius: float

    DrawableCustomPrimitive* = ref object of DrawablePrimitive
        vao, vbo: GLuint

    CustomBufferDrawable* = ref object of Drawable
        vao, vbo: GLuint

    StringDrawable* = ref object of Drawable
      text*: string
      font*: Font
      scale*: float
  
    R2D* = ref object
        drawables: TableRef[uint32, seq[Drawable]]
        stringDrawables: seq[StringDrawable]
        customDBufferDrawable: seq[CustomBufferDrawable]
        primitives: seq[DrawablePrimitive]
        
        postDrawingProcedures: seq[proc()]

        rotation_mode: RotationMode
        draw_instanced: bool
        drawable_counter: int
        last_drawable_counter: int
        layer_adder: float

        clear_color: Color
        rvao, rvbo, ribo: GLuint
        ortho_projection: M4
        view_matrix: M2

        viewport: (int, int)

        sprite_rectangle_batch_buffer: GLuint
        sprite_rot_and_depth_batch_buffer: GLuint
        sprite_quad_batch_buffer: GLuint
        sprite_color_batch_buffer: GLuint

        primitive_vao: GLuint
        primitive_vbo: GLuint

        shader_program: GLuint

        font_shader_program: GLuint
        font_text_color_location: GLint 

        font_text_vao: GLuint
        font_text_vbo: GLuint

        tiled_map_shader_program: GLuint

        diffuse_location:       GLint
        has_texture_location:   GLint
        size_location:          GLint
        rotation_location:      GLint
        position_location:      GLint
        depth_location:         GLint
        ortho_location:         GLint
        view_location:          GLint
        quad_location:          GLint

    # NOTES(Dustin): Were shelving this idea for now, just because cpu side clipping might actually be faster
    TileMapLayerDrawable* = ref object
        vao, vbo, ibo, tbo: GLuint

    TileMapDrawable* = ref object
        layers: seq[TileMapLayerDrawable]

# proc newTileMapDrawable* (map: TiledMap): TileMapDrawable=
#     result = TileMapDrawable(
#         layers: newSeq[TileMapLayerDrawable]()
#     )

#     for layer in map.layers:
#         for y in 0..<map.height:
#             for x in 0..<map.width:
#                 discard

proc newDrawable* (image: Image, region: Region, x, y, width, height: float, rotation: float, color: Color, layer = 0.5): Drawable=
  result = Drawable(
    image:      image,
    region:     region,
    x: x, y: y, width: width, height: height,
    rotation:   rotation,
    diffuse:    color,
    layer:      layer
  )

proc newStringDrawable* (font: Font, text: string, x, y: float, scale, rotation: float, color: Color, layer = 0.5): StringDrawable=
  result = StringDrawable(
    image:      nil,
    region:     nil,
    x: x, y: y, width: 0, height: 0,
    rotation:   rotation,
    diffuse:    color,
    layer:      layer,
    scale:      scale,
    text:       text,
    font:       font
  )

proc newR2D* (draw_instanced = true):R2d =
    result = R2D(
        clear_color: Black,
        drawables: newTable[uint32, seq[Drawable]](),
        stringDrawables: @[],
        customDBufferDrawable: newSeq[CustomBufferDrawable](),

        primitives: newSeq[DrawablePrimitive](),

        postDrawingProcedures: newSeq[proc()](),

        rotation_mode: RotationMode.Degrees,
        draw_instanced: draw_instanced,
        drawable_counter: 0,
        last_drawable_counter: 0,
        layer_adder: 0.0,
        viewport: (1280, 720)
    )

    var verts = RECT_VERTICES
    var indi = RECT_INDICES

    result.rvao = makeVao()
    result.rvbo = makeVbo(BT_ARRAY_BUFFER, 2, 0, verts)

    glGenBuffers(1, addr result.ribo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.ribo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLubyte) * indi.len, addr indi[0], GL_STATIC_DRAW)

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindVertexArray(0)

    # Font text buffers
    result.font_text_vao = makeVao()
    glGenBuffers(1, addr result.font_text_vbo)
    glBindBuffer(GL_ARRAY_BUFFER, result.font_text_vbo)

    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 6 * 4, nil, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, cGL_FLOAT, GL_FALSE, (4 * sizeof(GLfloat)).GLsizei, nil);

    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindVertexArray(0)

    # Instancing buffers
    # sprite_rectangle_batch_buffer: GLuint
    # sprite_rot_and_depth_batch_buffer: GLuint

    if result.draw_instanced:
        glGenBuffers(1, addr result.sprite_rectangle_batch_buffer)
        glGenBuffers(1, addr result.sprite_rot_and_depth_batch_buffer)
        glGenBuffers(1, addr result.sprite_quad_batch_buffer)
        glGenBuffers(1, addr result.sprite_color_batch_buffer)

    # Load the primitive buffer
    # result.primitive_vbo
    glGenBuffers(1, addr result.primitive_vbo)

    let vertex_shader =
        if result.draw_instanced:
            SPRITE_SHADER_VERTEX_INSTANCED
        else:
            SPRITE_SHADER_VERTEX
            
    result.shader_program = newProgram(
        loadShader(VERTEX_SHADER, vertex_shader),
        loadShader(FRAGMENT_SHADER, SPRITE_SHADER_FRAGMENT),
    )

    result.font_shader_program = newProgram(
        loadShader(VERTEX_SHADER, FONT_RENDERING_VERTEX),
        loadShader(FRAGMENT_SHADER, FONT_RENDERING_FRAGMENT)
    )

    result.tiled_map_shader_program = newProgram(
        loadShader(VERTEX_SHADER, TILED_MAP_VERTEX),
        loadShader(FRAGMENT_SHADER, TILED_MAP_FRAGMENT)
    )

    result.view_matrix = newM2(1, 0, 0, 1)

    glUseProgram(result.shader_program);

    useProgram result.shader_program:
      result.diffuse_location         = glGetUniformLocation(result.shader_program, "diffuse");
      result.depth_location           = glGetUniformLocation(result.shader_program, "depth");
      result.has_texture_location     = glGetUniformLocation(result.shader_program, "has_texture");
      result.ortho_location           = glGetUniformLocation(result.shader_program, "ortho");
      result.size_location            = glGetUniformLocation(result.shader_program, "size");
      result.rotation_location        = glGetUniformLocation(result.shader_program, "rotation");
      result.position_location        = glGetUniformLocation(result.shader_program, "position");
      result.quad_location            = glGetUniformLocation(result.shader_program, "quad");
      result.view_location            = glGetUniformLocation(result.shader_program, "view");

    useProgram result.font_shader_program:
      result.font_text_color_location = glGetUniformLocation(result.font_shader_program, "textColor");

    useProgram result.tiled_map_shader_program:
      discard

proc view* (self: R2D): auto= return self.view_matrix
proc `view=`* (self: R2D, view: M2)=
    self.view_matrix = view

proc `view=`* (self: R2D, camera: Camera2D)=
    self.view_matrix = camera.view

proc `viewport=`* (self: R2D, view: (int, int))=
    self.viewport = view

proc viewport* (self: R2D): (int, int)=
    return self.viewport

proc `rotationMode=`* (self: R2D, mode: RotationMode)=
    self.rotation_mode = mode

proc rotationMode* (self: R2D): auto=
    return self.rotation_mode

proc setBackgroundColor*(self: R2D, color: Color)=
    self.clear_color = color

proc getBackgroundColor*(self: R2D): auto= return self.clear_color

proc clear* (self: R2D)=
    glClearColor(
        self.clear_color.r,
        self.clear_color.g,
        self.clear_color.b,
        self.clear_color.a
        )
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc setLineWidth* (width = 1.0)=
    glLineWidth(4.0)

proc drawSprite* (self: R2D, image: Image, region: Region, x, y, width, height: float, rotation: float, color: Color, layer = 0.5)
proc drawSprite* (self: R2D, image: Image, region: Region, position: V2, size: V2, rotation: float, color: Color, layer = 0.5)=
    drawSprite(self, image, newRegion(0, 0, image.width, image.height), position.x, position.y, size.x, size.y, rotation, color, layer)

proc drawSprite* (self: R2D, image: Image, region: Region, x, y, width, height: float, rotation: float, color: Color, layer = 0.5)=
    let id = image.id
    if not self.drawables.hasKey id:
      self.drawables.add(id, newSeq[Drawable]())

    self.drawables[id].add(
        newDrawable(image, region, x, y, width, height, rotation, color, layer + self.layer_adder)
    )

    self.layer_adder += 0.0001
    self.drawable_counter += 1

proc drawImage*(self: R2D, image: Image, x, y, width, height: float, rotation: float = 0.0, color: Color, layer = 0.5)=
    drawSprite(self, image, newRegion(0, 0, image.width, image.height), x, y, width, height, rotation, color, layer)
    
proc drawImage*(self: R2D, image: Image, position: V2, size: V2, rotation: float = 0, color: Color, layer = 0.5)=
    drawSprite(self, image, newRegion(0, 0, image.width, image.height), position, size, rotation, color, layer)

proc drawRect*(self: R2D, x, y, width, height: float, rotation: float, color: Color, layer = 1.0)=
    self.primitives.add(DrawableRectanglePrimitive(
        x: x, y: y, width: width, height: height,
        color: color,
        layer: layer,
        rotation: rotation
    ))

proc drawRect*(self: R2D, position: V2, size: V2, rotation: float, color: Color, layer = 1.0)=
    self.drawRect(position.x, position.y, size.x, size.y, rotation, color, layer)

proc drawLineRect*(self: R2D, x, y, width, height: float, rotation: float, color: Color, layer = 1.0)=
    self.primitives.add(DrawableLineRectanglePrimitive(
        x: x, y: y, width: width, height: height,
        color: color,
        layer: layer,
        rotation: rotation
    ))

proc drawLineRect*(self: R2D, position: V2, size: V2, rotation: float, color: Color, layer = 1.0)=
    self.drawLineRect(position.x, position.y, size.x, size.y, rotation, color, layer)

proc drawString* (r2d: R2D, font: Font, text: string, pos: V2, scale = 1.0, color = White())=
    
  r2d.stringDrawables.add(
    newStringDrawable(
      font,
      text,
      pos.x, pos.y,
      scale,
      0,
      color))

# Drawing tiled maps
proc drawTileMap* (self: R2D, map: TileMap)=
  useProgram self.tiled_map_shader_program:
    let
        width = (float32)self.viewport[0]
        height = (float32)self.viewport[1]

    var ortho = NimMath.ortho(0, float32 width, float32 height, 0, -10.0'f32, 10.0'f32)
    #var ortho = NimMath.ortho(0.0, width.float32, 0.0, height.float32, -10.0, 10.0)
    let proj = glGetUniformLocation(self.tiled_map_shader_program, "projection")
    glUniformMatrix4fv(proj, 1, GL_TRUE, addr ortho.m[0])

    glBindTexture(GL_TEXTURE_2D, map.tileset.id)

    for drawlayer in map.layerDrawables:
      useVao drawlayer.vao:
        glDrawArrays(GL_TRIANGLES, 0,GLsizei drawlayer.verticesNum)

    glBindTexture(GL_TEXTURE_2D, 0)

var rectangle_batch = newSeq[GLfloat]()
var rot_and_depth_batch = newSeq[GLfloat]()
var quad_batch = newSeq[GLfloat]()
var color_batch = newSeq[GLfloat]()

proc begin* (self: R2D)=
    # glViewport(0, 0, cast[GLsizei](size[0]), cast[GLsizei](size[1]))
    let
        width = (float32)self.viewport[0]
        height = (float32)self.viewport[1]

    self.ortho_projection = NimMath.ortho(0, width, height, 0, -10.0'f32, 1.0'f32)

    var ortho = self.ortho_projection
    glUseProgram(self.shader_program)
    glUniformMatrix4fv(self.ortho_location, 1, GL_TRUE, addr ortho.m[0])

    var view = self.view_matrix
    glUniformMatrix2fv(self.view_location, 1, GL_TRUE, addr view.m[0])

    glBindVertexArray(self.rvao)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ribo)
    glEnable(GL_DEPTH_TEST)

    glActiveTexture(GL_TEXTURE0)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glLineWidth(4.0)

proc flush*(self: R2D)=
    begin(self) # @HARDCODED

    # Draw primitives
    for prim in self.primitives.reversed:

        if prim of DrawableRectanglePrimitive:
            let rprim = (DrawableRectanglePrimitive)prim
            glUniform4f(self.diffuse_location, rprim.color.r, rprim.color.g, rprim.color.b, rprim.color.a)

            glUniform1i(self.has_texture_location, 0)
            glUniform2f(self.position_location, rprim.x, rprim.y)
            glUniform2f(self.size_location, rprim.width, rprim.height)

            if self.rotation_mode == RotationMode.Degrees:
                glUniform1f(self.rotation_location, rprim.rotation * DEGTORAD)
            else:
                glUniform1f(self.rotation_location, rprim.rotation)

            glUniform1f(self.depth_location, 0 - rprim.layer)

            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)

        elif prim of DrawableLineRectanglePrimitive:
            let rprim = (DrawableLineRectanglePrimitive)prim
            glUniform4f(self.diffuse_location, rprim.color.r, rprim.color.g, rprim.color.b, rprim.color.a)

            glUniform1i(self.has_texture_location, 0)
            glUniform2f(self.position_location, rprim.x, rprim.y)
            glUniform2f(self.size_location, rprim.width, rprim.height)

            if self.rotation_mode == RotationMode.Degrees:
                glUniform1f(self.rotation_location, rprim.rotation * DEGTORAD)
            else:
                glUniform1f(self.rotation_location, rprim.rotation)

            glUniform1f(self.depth_location, 0 - rprim.layer)

            glDrawElements(GL_LINE_LOOP, 6, GL_UNSIGNED_BYTE, nil)

    # Draw drawables
    for key in self.drawables.keys:
        var drawables_seq = self.drawables[key]
        let number_of_drawables = drawables_seq.len
        
        # Bind the texture for the next sprites
        glBindTexture(GL_TEXTURE_2D, key)
        glUniform1i(self.has_texture_location, 1)

        drawables_seq.sort(proc(a, b: Drawable): int=
            result = cmp(a.layer, b.layer)
        )

        for drawable in drawables_seq:
            let color = drawable.diffuse
            let image = drawable.image
            let region = drawable.region

            let x = drawable.x
            let y = drawable.y
            let width = drawable.width
            let height = drawable.height

            var
                tw = float32(image.width)
                th = float32(image.height)
                rx = float32(region.x)
                ry = th - float32(region.y) - float32(region.h)
                qx = (rx / tw)
                qy = (ry / th)
                qw = (float32(region.w) / tw)
                qh = (float32(region.h) / th)

            if self.draw_instanced:
                rectangle_batch.add(x)
                rectangle_batch.add(y)
                rectangle_batch.add(width)
                rectangle_batch.add(height)

                quad_batch.add(qx)
                quad_batch.add(qy)
                quad_batch.add(qw)
                quad_batch.add(qh)

                color_batch.add(color.r)
                color_batch.add(color.g)
                color_batch.add(color.b)
                color_batch.add(color.a)

            else:
                glUniform4f(self.diffuse_location, color.r, color.g, color.b, color.a)
                glUniform4f(self.quad_location, qx, qy, qw, qh,)

            glUniform2f(self.position_location, x, y)
            glUniform2f(self.size_location, width, height)

            if self.rotation_mode == RotationMode.Degrees:
                if self.draw_instanced:
                    rot_and_depth_batch.add(drawable.rotation * DEGTORAD)
                else:
                    glUniform1f(self.rotation_location, drawable.rotation * DEGTORAD)
            else:
                if self.draw_instanced:
                    rot_and_depth_batch.add(drawable.rotation)
                else:
                    glUniform1f(self.rotation_location, drawable.rotation)

            if self.draw_instanced:
                rot_and_depth_batch.add(0 - drawable.layer)
            else:
                glUniform1f(self.depth_location, 0 - drawable.layer)
                glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)

        if self.draw_instanced:
            # Set the buffers
            glBindBuffer(GL_ARRAY_BUFFER, self.sprite_rectangle_batch_buffer)
            glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * rectangle_batch.len, addr rectangle_batch[0], GL_DYNAMIC_DRAW)
            glEnableVertexAttribArray(1)
            glVertexAttribPointer(1, 4, cGL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), nil)

            glBindBuffer(GL_ARRAY_BUFFER, self.sprite_rot_and_depth_batch_buffer)
            glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * rot_and_depth_batch.len, addr rot_and_depth_batch[0], GL_DYNAMIC_DRAW)
            glEnableVertexAttribArray(2)
            glVertexAttribPointer(2, 2, cGL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), nil)

            glBindBuffer(GL_ARRAY_BUFFER, self.sprite_quad_batch_buffer)
            glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * quad_batch.len, addr quad_batch[0], GL_DYNAMIC_DRAW)
            glEnableVertexAttribArray(3)
            glVertexAttribPointer(3, 4, cGL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), nil)

            glBindBuffer(GL_ARRAY_BUFFER, self.sprite_color_batch_buffer)
            glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * color_batch.len, addr color_batch[0], GL_DYNAMIC_DRAW)
            glEnableVertexAttribArray(4)
            glVertexAttribPointer(4, 4, cGL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), nil)

            # Divisors
            glVertexAttribDivisor(1, 1)
            glVertexAttribDivisor(2, 1)
            glVertexAttribDivisor(3, 1)
            glVertexAttribDivisor(4, 1)

            glDrawElementsInstanced(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil, number_of_drawables.GLsizei)

            rectangle_batch.setLen 0
            rot_and_depth_batch.setLen 0
            quad_batch.setLen 0
            color_batch.setLen 0

        # unbind the texture
        glBindTexture(GL_TEXTURE_2D, 0)

        # Clear the sequence for the next frame

        self.drawables[key].setLen(0)

    # Draw all text primitives
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    # glEnable(GL_ALPHA_TEST)
    # glAlphaFunc(GL_GREATER, 0.01)

    glUseProgram(self.font_shader_program)

    let
        width = (float32)self.viewport[0]
        height = (float32)self.viewport[1]

    # var ortho = NimMath.ortho(0, width, height, 0, -10.0'f32, 1.0'f32)
    var ortho = NimMath.ortho(0.0, width.float32, 0.0, height.float32, -10.0, 10.0)
    # var ortho = self.ortho_projection

    let proj = glGetUniformLocation(self.font_shader_program, "projection")
    glUniformMatrix4fv(proj, 1, GL_TRUE, addr ortho.m[0])
    
    glActiveTexture(GL_TEXTURE0)
    glBindVertexArray(self.font_text_vao)
    glBindBuffer(GL_ARRAY_BUFFER, self.font_text_vbo)

    for stringDraw in self.stringDrawables:
      var x = stringDraw.x
      var y = height - stringDraw.y
      var text = stringDraw.text
      var font = stringDraw.font
      let scale = stringDraw.scale

      glUniform3f(
        self.font_text_color_location,
        stringDraw.diffuse.r,
        stringDraw.diffuse.g,
        stringDraw.diffuse.b)

      var bs = font.measure(text, scale)
      #var bw = bs.x
      var bh = bs.y

      # var vertices = newSeq[float](6 * 4)
      for c in text:
          doAssert(font.characters.hasKey c, "Font did not load the character: " & $c)
          let g = font.characters[c]

          let xpos = x + g.bearing.x * scale

          var ypos = y - ((g.size.y - g.bearing.y) * scale)

          let w = g.size.x * scale
          let h = g.size.y * scale

          ypos -= bh

          var vertices = @[
              (xpos).GLfloat,     (ypos + h).GLfloat,   0.0.GLfloat, 0.0.GLfloat,
              (xpos).GLfloat,     (ypos).GLfloat,       0.0.GLfloat, 1.0.GLfloat,
              (xpos + w).GLfloat, (ypos).GLfloat,       1.0.GLfloat, 1.0.GLfloat,
              (xpos).GLfloat,     (ypos + h).GLfloat,   0.0.GLfloat, 0.0.GLfloat,
              (xpos + w).GLfloat, (ypos).GLfloat,       1.0.GLfloat, 1.0.GLfloat,
              (xpos + w).GLfloat, (ypos + h).GLfloat,   1.0.GLfloat, 0.0.GLfloat
          ]

          glBindTexture(GL_TEXTURE_2D, g.texture_id)
          glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(GLfloat) * 6 * 4, addr vertices[0]); 

          glDrawArrays(GL_TRIANGLES, 0, 6)

          x += (g.advance shr 6).float * scale

    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindVertexArray(0)
    glUseProgram(0)
    # glDisable(GL_ALPHA_TEST)
    
    # self.last_drawable_counter = self.drawable_counter
    # self.drawable_counter = 0
    self.primitives.setLen(0)
    self.stringDrawables.setLen(0)
    self.layer_adder = 0.0

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    glBindVertexArray(0)
    glUseProgram(0)
    glDisable(GL_BLEND)

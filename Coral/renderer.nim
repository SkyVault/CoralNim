import 
    graphics,
    opengl,
    tables,
    gameMath as NimMath,
    math,
    strutils,
    algorithm

include shaders

## NOTES ABOUT BATCHING
#[
    The renderer does support batching the sprites and instancing them, several problems arise
    when I do this though, on of which is that I cant do primitives like I would want. Second
    the batch isnt as fast as I imagined. Finally, with batching you cant play with different 
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
    CoralRotationMode* {.pure.} = enum
        Degrees,
        Radians

    CoralBlendMode* {.pure.} = enum
        Alpha,
        Additive

    # image: Image, region: Region, position: V2, size: V2, rotation: float, color: Color, layer = 0.5
    Drawable* = ref object
      image: Image
      region: Region
      position: V2
      size: V2
      rotation: float
      diffuse: Color
      layer: float
  
    R2D* = ref object
        drawables: TableRef[uint32, seq[Drawable]]

        rotation_mode: CoralRotationMode
        draw_instanced: bool
        drawable_counter: int
        last_drawable_counter: int
        layer_adder: float

        clear_color: Color
        rvao, rvbo, ribo: GLuint
        ortho_projection: M4
        view_matrix: M2

        sprite_rectangle_batch_buffer: GLuint
        sprite_rot_and_depth_batch_buffer: GLuint
        sprite_quad_batch_buffer: GLuint
        sprite_color_batch_buffer: GLuint

        primitive_vao: GLuint
        primitive_vbo: GLuint

        shader_program: GLuint

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

proc newDrawable* (image: Image, region: Region, position: V2, size: V2, rotation: float, color: Color, layer = 0.5): Drawable=
  Drawable(
    image:      image,
    region:     region,
    position:   position,
    size:       size,
    rotation:   rotation,
    diffuse:    color,
    layer:      layer
  )

proc newR2D* (draw_instanced = true):R2d =
    result = R2D(
        clear_color: Black,
        drawables: newTable[uint32, seq[Drawable]](),
        rotation_mode: CoralRotationMode.Degrees,
        draw_instanced: draw_instanced,
        drawable_counter: 0,
        last_drawable_counter: 0,
        layer_adder: 0.0
    )

    var verts = RECT_VERTICES
    var indi = RECT_INDICES

    result.rvao = makeVao()
    result.rvbo = makeVbo(BT_ARRAY_BUFFER, 2, 0, verts)

    glGenBuffers(1, addr result.ribo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.ribo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLubyte) * indi.len, addr indi[0], GL_STATIC_DRAW)

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
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
            
    result.shader_program = CoralNewProgram(
        CoralLoadShader(VERTEX_SHADER, vertex_shader),
        CoralLoadShader(FRAGMENT_SHADER, SPRITE_SHADER_FRAGMENT),
    )

    result.view_matrix = newM2(1, 0, 0, 1)

    glUseProgram(result.shader_program);
    result.diffuse_location         = glGetUniformLocation(result.shader_program, "diffuse");
    result.depth_location           = glGetUniformLocation(result.shader_program, "depth");
    result.has_texture_location     = glGetUniformLocation(result.shader_program, "has_texture");
    result.ortho_location           = glGetUniformLocation(result.shader_program, "ortho");
    result.size_location            = glGetUniformLocation(result.shader_program, "size");
    result.rotation_location        = glGetUniformLocation(result.shader_program, "rotation");
    result.position_location        = glGetUniformLocation(result.shader_program, "position");
    result.quad_location            = glGetUniformLocation(result.shader_program, "quad");
    result.view_location            = glGetUniformLocation(result.shader_program, "view");
    glUseProgram(0);

proc view* (self: R2D): auto= return self.view_matrix
proc `view=`* (self: R2D, view: M2)=
    self.view_matrix = view

proc `view=`* (self: R2D, camera: Camera2D)=
    self.view_matrix = camera.view

proc `rotationMode=`* (self: R2D, mode: CoralRotationMode)=
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

proc begin* (self: R2D, size: (int, int))=
    glViewport(0, 0, cast[GLsizei](size[0]), cast[GLsizei](size[1]))
    let
        width = (float32)size[0]
        height = (float32)size[1]

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

    # glEnable(GL_ALPHA_TEST)
    # glAlphaFunc(GL_GREATER, 0.01)

    glLineWidth(4.0)

proc setLineWidth* (width = 1.0)=
    glLineWidth(4.0)

proc drawSprite* (self: R2D, image: Image, region: Region, position: V2, size: V2, rotation: float, color: Color, layer = 0.5)=
    let id = image.id
    if not self.drawables.hasKey id:
      self.drawables.add(id, newSeq[Drawable]())

    # if self.drawable_counter < self.drawables[image.getID()].len() - 1:
    #     var drawable = self.drawables[image.getID()][self.drawable_counter]
    #     drawable.image      = image
    #     drawable.region     = region
    #     drawable.position   = position 
    #     drawable.size       = size 
    #     drawable.rotation   = rotation 
    #     drawable.diffuse    = color
    #     drawable.layer      = layer 
    # else:
    #     self.drawables[image.getID()].add(
    #         newDrawable(image, region, position, size, rotation, color, layer)
    #     )

    self.drawables[id].add(
        newDrawable(image, region, position, size, rotation, color, layer + self.layer_adder)
    )

    self.layer_adder += 0.0001
    self.drawable_counter += 1

proc drawImage*(self: R2D, image: Image, position: V2, size: V2, rotation: float = 0, color: Color, layer = 0.5)=
    drawSprite(self, image, newRegion(0, 0, image.width, image.height), position, size, rotation, color, layer)

proc drawRect*(self: R2D, x, y, width, height: float, rotation: float, color: Color, layer = 1.0)=
    glUniform4f(self.diffuse_location, color.r, color.g, color.b, color.a)

    glUniform1i(self.has_texture_location, 0)
    glUniform2f(self.position_location, x, y)
    glUniform2f(self.size_location, width, height)

    if self.rotation_mode == CoralRotationMode.Degrees:
        glUniform1f(self.rotation_location, rotation * DEGTORAD)
    else:
        glUniform1f(self.rotation_location, rotation)

    glUniform1f(self.depth_location, 0 - layer)

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)

proc drawRect*(self: R2D, position: V2, size: V2, rotation: float, color: Color, layer = 1.0)=
    self.drawRect(position.x, position.y, size.x, size.y, rotation, color, layer)

proc drawLineRect*(self: R2D, x, y, width, height: float, rotation: float, color: Color, layer = 1.0)=
    glUniform4f(self.diffuse_location, color.r, color.g, color.b, color.a)

    glUniform1i(self.has_texture_location, 0)
    glUniform2f(self.position_location, x, y)
    glUniform2f(self.size_location, width, height)

    if self.rotation_mode == CoralRotationMode.Degrees:
        glUniform1f(self.rotation_location, rotation * DEGTORAD)
    else:
        glUniform1f(self.rotation_location, rotation)

    glUniform1f(self.depth_location, 0 - layer)

    glDrawElements(GL_LINE_LOOP, 6, GL_UNSIGNED_BYTE, nil)

proc drawLineRect*(self: R2D, position: V2, size: V2, rotation: float, color: Color, layer = 1.0)=
    self.drawLineRect(position.x, position.y, size.x, size.y, rotation, color, layer)

# proc drawTriangle* (self: R2D)=
# proc drawTiledMap* (self: R2D, map: TiledMap, scale: float32 = 1.0)=
#     let image = map.image
#     bindImage(image)
#     glUniform4f(self.diffuse_location, 1.0, 1.0, 1.0, 1.0)
#     glUniform1i(self.has_texture_location, 1)
#     glUniform2f(self.size_location, (float32)(map.tilewidth) * scale, (float32)(map.tileheight) * scale)
#     glUniform1f(self.rotation_location, 0.0)
#     glUniform1f(self.depth_location, 0.0)

#     var 
#         tw = float32(image.width)
#         th = float32(image.height)

#     for layer in map.layers:
#         # @Important
#         # Quick fix, need to look into why the object layer is
#         # getting added to the tile layers sequence?
#         if layer.data.len <= 0: continue 
#         for y in 0.. < map.height:
#             for x in 0.. < map.width:
#                 let tid = layer.data[x + y * map.width]
#                 if tid != 0:
#                     let id = tid - 1
#                     let region = map.quads[id]

#                     var
#                         rx = float32(region.x)
#                         ry = th - float32(region.y) - float32(region.h)
#                         qx = (rx / tw)
#                         qy = (ry / th)
#                         qw = (float32(region.w) / tw)
#                         qh = (float32(region.h) / th)

#                     glUniform4f(self.quad_location,
#                         qx,
#                         qy,
#                         qw,
#                         qh)

#                     glUniform2f(
#                       self.position_location,
#                       (float32)(x * map.tilewidth) * scale,
#                       (float32)(y * map.tileheight) * scale
#                     )

#                     glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)


#     unBindImage()

proc drawString* (r2d: R2D, font: SpriteFont, text: string, x, y: float, scale = 1.0, color = White())=
  var
    cursor_x = x
    cursor_y = y

  for c in text:
    let id = uint(c)

    if not font.glyphs.hasKey id:
      continue

    if c == ' ':
      cursor_x += font.glyphs[uint(' ')].xadvance * scale
      continue
    if c in Newlines:
      cursor_x = x
      cursor_y += (float)(font.glyphs[uint('A')].region.h) * scale
      continue

    let glyph = font.glyphs[id]

    r2d.drawSprite(
      font.image,
      glyph.region,
      newV2(
        x + cursor_x,
        y + cursor_y + (glyph.yoffset) * scale,
      ),
      newV2(
        (float32)(glyph.region.w) * (float32)(scale),
        (float32)(glyph.region.h) * (float32)(scale)
      ),
      (float)0.0,
      color,
      1.0
    )

    cursor_x += ((float32)(glyph.region.w) + glyph.xoffset) * scale

var rectangle_batch = newSeq[GLfloat]()
var rot_and_depth_batch = newSeq[GLfloat]()
var quad_batch = newSeq[GLfloat]()
var color_batch = newSeq[GLfloat]()

proc flush*(self: R2D)=
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
            let position = drawable.position
            let size = drawable.size

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
                rectangle_batch.add(position.x)
                rectangle_batch.add(position.y)
                rectangle_batch.add(size.x)
                rectangle_batch.add(size.y)

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

            glUniform2f(self.position_location, position.x, position.y)
            glUniform2f(self.size_location, size.x, size.y)

            if self.rotation_mode == CoralRotationMode.Degrees:
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

    # self.last_drawable_counter = self.drawable_counter
    # self.drawable_counter = 0
    self.layer_adder = 0.0

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    glBindVertexArray(0)
    glUseProgram(0)
    glDisable(GL_BLEND)

    

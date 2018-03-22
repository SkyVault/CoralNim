import 
    graphics,
    opengl,
    tables,
    gameMath as NimMath,
    math,
    strutils,
    algorithm

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

const SPRITE_SHADER_VERTEX = """
#version 330 core
layout (location = 0) in vec2 Vertex;
out vec2 uvs;

uniform vec2 position;
uniform vec2 size;
uniform float rotation = 0.0;
uniform float depth = 0.5;

uniform vec4 quad;
uniform mat4 view;
uniform mat4 ortho;

void main() {
    vec2 tuvs = Vertex * 1.0 + 0.5;
    tuvs.y = 1 - tuvs.y;

    uvs.x = (quad.x + (tuvs.x * quad.z));
    uvs.y = (quad.y + (tuvs.y * quad.w));
  
    float s = sin(rotation);
    float c = cos(rotation);
    mat2 rot = mat2(c, -s, s, c);
    vec2 pos = position + (size * ((rot * Vertex) + 0.5));
    gl_Position = ortho * view * vec4(pos, 0.0, 1.0) + vec4(0, 0, depth, 0.0);
}
"""

const SPRITE_SHADER_FRAGMENT = """
#version 330 core
in vec2 uvs;
uniform bool has_texture = true;
uniform sampler2D sampler;
uniform vec4 diffuse;
void main() {
  vec4 result = vec4(0.0);
	if (has_texture){
		result = diffuse * texture(sampler, uvs);
	} else {
		result = diffuse;
	}
  
  if (result.a <= 0.1) discard;
  gl_FragColor = result;
}
"""

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

        clear_color: Color
        rvao, rvbo, ribo: GLuint
        ortho_projection: M4
        view_matrix: M4

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

proc newR2D* ():R2d =
    result = R2D(
      clear_color: Black,
      drawables: newTable[uint32, seq[Drawable]]()
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

    result.shader_program = newProgram(
        loadShader(VERTEX_SHADER, SPRITE_SHADER_VERTEX),
        loadShader(FRAGMENT_SHADER, SPRITE_SHADER_FRAGMENT),
    )

    result.view_matrix = identity()

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

proc setView* (self: R2D, view: M4)=
  self.view_matrix = view

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

    self.ortho_projection = NimMath.ortho(0, width, height, 0, -1.0'f32, 1.0'f32)

    var ortho = self.ortho_projection
    glUseProgram(self.shader_program)
    glUniformMatrix4fv(self.ortho_location, 1, GL_TRUE, addr ortho.m[0])

    var view = self.view_matrix
    glUseProgram(self.shader_program)
    glUniformMatrix4fv(self.view_location, 1, GL_TRUE, addr view.m[0])

    glBindVertexArray(self.rvao)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ribo)
    glEnable(GL_DEPTH_TEST)

    glActiveTexture(GL_TEXTURE0)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glLineWidth(4.0)

proc setLineWidth* (width = 1.0)=
    glLineWidth(4.0)

proc drawSprite* (self: R2D, image: Image, region: Region, position: V2, size: V2, rotation: float, color: Color, layer = 0.5)=
    if not self.drawables.hasKey image.getId():
      self.drawables.add(image.getId(), newSeq[Drawable]())

    self.drawables[image.getId()].add(
      newDrawable(image, region, position, size, rotation, color, layer)
    )

proc drawImage*(self: R2D, image: Image, position: V2, size: V2, rotation: float = 0, color: Color)=
    drawSprite(self, image, newRegion(0, 0, image.width, image.height), position, size, rotation, color)

proc drawRect*(self: R2D, x, y, width, height: float, rotation: float, color: Color, layer = 1.0)=
    glUniform4f(self.diffuse_location, color.r, color.g, color.b, color.a)

    glUniform1i(self.has_texture_location, 0)
    glUniform2f(self.position_location, x, y)
    glUniform2f(self.size_location, width, height)
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
    glUniform1f(self.rotation_location, rotation)
    glUniform1f(self.depth_location, 0 - layer)

    glDrawElements(GL_LINE_LOOP, 6, GL_UNSIGNED_BYTE, nil)

proc drawLineRect*(self: R2D, position: V2, size: V2, rotation: float, color: Color, layer = 1.0)=
    self.drawLineRect(position.x, position.y, size.x, size.y, rotation, color, layer)

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

proc flush*(self: R2D)=
    for key in self.drawables.keys:
      
      # Bind the texture for the next sprites
      glBindTexture(GL_TEXTURE_2D, key)
      
      var drawables_seq = self.drawables[key]

      # Sort the drawables_seq by the sprites layer from back to front
      #drawables_seq.reverse()

      for drawable in drawables_seq:
        let color = drawable.diffuse
        let image = drawable.image
        let region = drawable.region
        let position = drawable.position
        let size = drawable.size

        glUniform4f(self.diffuse_location, color.r, color.g, color.b, color.a)

        glUniform1i(self.has_texture_location, 1)

        var
            tw = float32(image.width)
            th = float32(image.height)
            rx = float32(region.x)
            ry = th - float32(region.y) - float32(region.h)
            qx = (rx / tw)
            qy = (ry / th)
            qw = (float32(region.w) / tw)
            qh = (float32(region.h) / th)

        glUniform4f(self.quad_location,
            qx,
            qy,
            qw,
            qh,
            )

        glUniform2f(self.position_location, position.x, position.y)
        glUniform2f(self.size_location, size.x, size.y)
        glUniform1f(self.rotation_location, drawable.rotation)
        glUniform1f(self.depth_location, 0 - drawable.layer)

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, nil)
      
      # unbind the texture
      glBindTexture(GL_TEXTURE_2D, 0)

      # Clear the sequence for the next frame
      self.drawables[key].setLen(0)

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    glBindVertexArray(0)
    glUseProgram(0)
    glDisable(GL_BLEND)
    

import
  nim_tiled,
  sequtils,
  opengl,
  graphics

type
  LayerDrawable* = object
    vao*, vbo*, ibo*, tbo*: GLuint
    verticesNum*: int
    indicesNum*: int

  TileMap* = ref object
    tiledMap*: TiledMap
    tileset*: Image
    layerDrawables*: seq[LayerDrawable]

proc loadTileMap* (path: string): TileMap=
  result = TileMap()
  result.tiledMap = loadTiledMap(path)
  result.layerDrawables = newSeq[LayerDrawable](result.tiledMap.layers.len)

  let tileset = result.tiledMap.tilesets[0]
  result.tileset = loadImage(tileset.imagePath)

  let tilewidth = result.tiledMap.tilewidth * 4
  let tileheight = result.tiledMap.tileheight * 4
  
  var i = 0
  for layer in result.tiledMap.layers:
    var drawable = LayerDrawable()

    var v = newSeq[float32]()
    var t = newSeq[GLfloat]()

    proc addQuad(x, y, w, h: float32, tid: int)=
      v.add(x + 0); v.add(y + h)
      v.add(x + 0); v.add(y + 0)
      v.add(x + w); v.add(y + h)

      v.add(x + w); v.add(y + h)
      v.add(x + 0); v.add(y + 0)
      v.add(x + w); v.add(y + 0)

      var quad: TiledRegion = tileset.regions[tid - 1]
      let ux = quad.x.float / tileset.width.float
      let uy = quad.y.float / tileset.height.float
      let uw = quad.width.float / tileset.width.float
      let uh = quad.height.float / tileset.height.float

      #t.add(1); t.add(0);
      #t.add(1); t.add(0);
      #t.add(0); t.add(1);
      #t.add(1); t.add(0);
      #t.add(0); t.add(1);
      #t.add(1); t.add(1);

      t.add(0); t.add(0);
      t.add(0); t.add(1);
      t.add(1); t.add(1);
      t.add(1); t.add(0);

    for y in 0..<layer.height:
      for x in 0..<layer.width:
        let index = x + y * layer.width
        let tid = layer.tiles[index]

        if tid != 0:
          addQuad(float32(x * tilewidth), float32(y * tileheight),float32(tilewidth),float32(tileheight), tid)

    drawable.verticesNum = len(v)

    drawable.vao = newVao()
    useVao drawable.vao:
      drawable.vbo = newVbo(
        BufferType.VERTEX_BUFFER,
        2,
        0,
        v
      )

      drawable.tbo = newVbo(
        BufferType.VERTEX_BUFFER,
        2,
        1,
        t
      )
    
    result.layerDrawables[i] = drawable
    inc i

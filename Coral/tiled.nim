import
  nim_tiled,
  sequtils,
  opengl,
  graphics

type
  LayerDrawable* = object
    vao, vbo, ibo, tbo: GLuint

  TileMap* = ref object
    tiledMap: TiledMap
    tileset: Image
    layerDrawables: seq[LayerDrawable]

proc loadTileMap* (path: string): TileMap=
  result = TileMap()
  result.tiledMap = loadTiledMap(path)
  result.layerDrawables = newSeq[LayerDrawable](result.tiledMap.layers.len)

  let tileset = result.tiledMap.tilesets[0]
  result.tileset = loadImage(tileset.imagePath)

  for layer in result.tiledMap.layers:
    var drawable = LayerDrawable()
    var vertices = @[0.5'f32, 1'f32, 1.0'f32, -1'f32, -1.0'f32, -1'f32]

    drawable.vao = newVao()
    useVao drawable.vao:
      drawable.vbo = newVbo(
        BufferType.VERTEX_BUFFER,
        2,
        0,
        vertices
      )
      echo drawable.vbo

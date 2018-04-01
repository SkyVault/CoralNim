import 
    xmlparser, 
    xmltree, 
    streams,
    strutils,
    graphics,
    os,
    game,
    ospaths

type
    TiledLayer* = ref object
    TiledObject* = ref object

    TiledOrientation {.pure.} = enum
        Orthogonal,
        Orthographic

    TiledRenderorder {.pure.} = enum
        RightDown

    TiledTileset* = ref object
        name: string
        tilewidth, tileheight: int
        tilecount: int
        columns: int
        image: Image

    TiledMap* = ref object
        version: string
        tiledversion: string
        orientation: TiledOrientation
        renderorder: TiledRenderorder

        width, height: int
        tilewidth, tileheight: int
        infinite: bool

        tilesets: seq[TiledTileset]

    
proc loadTileset* (path: string): TiledTileset=
    assert(fileExists path, "[ERROR] :: loadTiledMap :: Cannot find tileset: " & path)

    result = TiledTileset()
    let theXml = readFile(path)
        .newStringStream()
        .parseXml()
    
    result.name         = theXml.attr "name"
    result.tilewidth    = theXml.attr("tilewidth").parseInt
    result.tileheight   = theXml.attr("tileheight").parseInt
    result.tilecount    = theXml.attr("tilecount").parseInt
    result.tilecount    = theXml.attr("columns").parseInt

    let imageXml = theXml[0]
    let tpath = parentDir(path) & "/" & imageXml.attr("source")

    if not Coral.assets.imageExists tpath:
        result.image = CoralLoadImage tpath
        Coral.assets.add(tpath, result.image)
    else:
        result.image = Coral.assets.getImage tpath


proc loadTiledMap* (path: string): TiledMap=
    assert(fileExists path, "[ERROR] :: loadTiledMap :: Cannot find map: " & path)

    result = TiledMap(
        tilesets: newSeq[TiledTileset]()
    )

    let theXml = readFile(path)
        .newStringStream()
        .parseXml()

    result.version = theXml.attr "version"
    result.tiledversion = theXml.attr "tiledversion"

    result.orientation = 
        if theXml.attr("orientation") == "orthogonal":
            TiledOrientation.Orthogonal
        else:
            TiledOrientation.Orthogonal
        
    result.renderorder =
        if theXml.attr("renderorder") == "right-down":
            TiledRenderorder.RightDown
        else:
            TiledRenderorder.RightDown
        
    result.width = theXml.attr("width").parseInt
    result.height = theXml.attr("height").parseInt

    result.tilewidth = theXml.attr("tilewidth").parseInt
    result.tileheight = theXml.attr("tileheight").parseInt

    result.infinite = 
        if theXml.attr("infinite") == "0":
            false
        else:
            true

    let tileset_xmlnodes = theXml.findAll "tileset"
    for node in tileset_xmlnodes:
        let tpath = parentDir(path) & "/" & node.attr "source"
        result.tilesets.add loadTIleset(tpath)
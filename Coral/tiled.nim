import
    xmlparser,
    xmltree,
    streams,
    strutils,
    graphics,
    os

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
    
proc loadTileset* (path: string): TiledTileset=
    assert(fileExists path, "[ERROR] :: loadTiledMap :: Cannot find tileset: " & path)

    result = TiledTileset()
    let theXml = readFile(path)
        .newStringStream()
        .parseXml()
    
    echo theXml

proc loadTiledMap* (path: string): TiledMap=
    assert(fileExists path, "[ERROR] :: loadTiledMap :: Cannot find map: " & path)

    result = TiledMap()
        
    let mapcode = readFile path    
    let document = newStringStream mapcode 
    let theXml = document.parseXml

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

    # for node: XmlNode in theXml.items:
    #     case node.tag

    let tileset_xmlnodes = theXml.findAll "tileset"
    for node in tileset_xmlnodes:
        echo node.attr "source"
        echo node.attr "firstgid"
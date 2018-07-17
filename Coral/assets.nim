import 
    graphics,
    audio,
    tables

type
    AssetManager* = ref object
        images*: TableRef[string, Image]
        audio*: TableRef[string, Audio]
        regions*: TableRef[string, seq[Region]]
        fonts*: TableRef[string, Font]

## Asset manager Api
proc add* (a: AssetManager, id: string, image: Image): Image{.discardable.}=
    result = image
    a.images.add(id, image)

proc add* (a: AssetManager, id: string, font: Font): Font{.discardable.}=
    result = font
    a.fonts.add(id, font)

proc add* (a: AssetManager, id: string, regions: seq[Region]): seq[Region]{.discardable.}=
    result = regions
    a.regions.add(id, regions)

proc add* (a: AssetManager, id: string, audio: Audio): Audio{.discardable.}=
    result = audio
    a.audio.add(id, audio)

proc getImage* (a: AssetManager, id: string): Image=
    return a.images[id]
    
proc getAudio* (a: AssetManager, id: string): Audio=
    return a.audio[id]

proc getFont* (a: AssetManager, id: string): Font=
    return a.fonts[id]

proc getRegions* (a: AssetManager, id: string): seq[Region]=
    return a.regions[id]

proc imageExists* (a: AssetManager, id: string): bool=
    return a.images.hasKey id
    
proc audioExists* (a: AssetManager, id: string): bool=
    return a.audio.hasKey id

proc regionsExists* (a: AssetManager, id: string): bool=
    return a.regions.hasKey id

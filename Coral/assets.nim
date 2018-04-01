import 
    graphics,
    audio,
    tables

type
    CoralAssetManager* = ref object
        images*: TableRef[string, Image]
        audio*: TableRef[string, Audio]
        regions*: TableRef[string, seq[Region]]

## Asset manager Api
proc add* (a: CoralAssetManager, id: string, image: Image): Image{.discardable.}=
    result = image
    a.images.add(id, image)

proc add* (a: CoralAssetManager, id: string, regions: seq[Region]): seq[Region]{.discardable.}=
    result = regions
    a.regions.add(id, regions)

proc add* (a: CoralAssetManager, id: string, audio: Audio): Audio{.discardable.}=
    result = audio 
    a.audio.add(id, audio)

proc getImage* (a: CoralAssetManager, id: string): Image=
    return a.images[id]
    
proc getAudio* (a: CoralAssetManager, id: string): Audio=
    return a.audio[id]

proc getRegions* (a: CoralAssetManager, id: string): seq[Region]=
    return a.regions[id]

proc imageExists* (a: CoralAssetManager, id: string): bool=
    return a.images.hasKey id
    
proc audioExists* (a: CoralAssetManager, id: string): bool=
    return a.audio.hasKey id

proc regionsExists* (a: CoralAssetManager, id: string): bool=
    return a.regions.hasKey id
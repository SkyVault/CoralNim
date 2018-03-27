import openal, data_source_al
import streams, logging

type Sound* = ref object
    mDataSource: DataSource
    src: ALuint
    mGain: ALfloat
    mLooping: bool

var activeSounds: seq[Sound]

proc finalizeSound(s: Sound) =
    if s.src != 0: alDeleteSources(1, addr s.src)

proc destroy* (s: Sound)=
    if s.src != 0:
        alDeleteSources(1, addr s.src)

proc destroyAllSounds* ()=
    for sound in activeSounds:
        sound.destroy()

proc newSound(): Sound =
    result.new(finalizeSound)
    result.mGain = 1

proc `dataSource=`(s: Sound, ds: DataSource) = # Private for now. Should be public eventually
    s.mDataSource = ds

proc newSoundWithPCMData*(data: pointer, dataLength, channels, bitsPerSample, samplesPerSecond: int): Sound =
    ## This function is only availbale for openal for now. Sorry.
    result = newSound()
    result.dataSource = newDataSourceWithPCMData(data, dataLength, channels, bitsPerSample, samplesPerSecond)

proc newSoundWithPCMData*(data: openarray[byte], channels, bitsPerSample, samplesPerSecond: int): Sound {.inline.} =
    ## This function is only availbale for openal for now. Sorry.
    newSoundWithPCMData(unsafeAddr data[0], data.len, channels, bitsPerSample, samplesPerSecond)

proc newSoundWithFile*(path: string): Sound =
    result = newSound()
    result.dataSource = newDataSourceWithFile(path)

proc newSoundWithStream*(s: Stream): Sound =
    result = newSound()
    result.dataSource = newDataSourceWithStream(s)

proc isSourcePlaying(src: ALuint): bool {.inline.} =
    var state: ALenum
    alGetSourcei(src, AL_SOURCE_STATE, addr state)
    result = state == AL_PLAYING

proc isPlaying* (sound: Sound): bool {.inline.} =
    let src: ALuint = sound.src
    var state: ALenum
    alGetSourcei(src, AL_SOURCE_STATE, addr state)
    result = state == AL_PLAYING

proc duration*(s: Sound): float {.inline.} = s.mDataSource.mDuration

proc setLooping*(s: Sound, flag: bool) =
    s.mLooping = flag
    if s.src != 0:
        alSourcei(s.src, AL_LOOPING, ALint(flag))

proc looping* (s: Sound): bool=
    if s.src != 0:
        var value: ALint = 0
        alGetSourcei(s.src, AL_LOOPING, addr value)
        return 
            if value == 0:
                false
            else:
                true
    else:
        return false

proc reclaimInactiveSource(): ALuint {.inline.} =
    for i in 0 ..< activeSounds.len:
        let src = activeSounds[i].src
        if not src.isSourcePlaying:
            result = src
            activeSounds[i].src = 0
            activeSounds.del(i)
            break

proc stop*(s: Sound) =
    if s.src != 0:
        alSourceStop(s.src)

proc play*(s: Sound) =
    if s.mDataSource.mBuffer != 0:
        if s.src == 0:
            s.src = reclaimInactiveSource()
            if s.src == 0:
                alGenSources(1, addr s.src)
            alSourcei(s.src, AL_BUFFER, cast[ALint](s.mDataSource.mBuffer))
            alSourcef(s.src, AL_GAIN, s.mGain)
            alSourcei(s.src, AL_LOOPING, ALint(s.mLooping))
            alSourcePlay(s.src)
            if activeSounds.isNil: activeSounds = @[]
            activeSounds.add(s)
        else:
            alSourceStop(s.src)
            alSourcePlay(s.src)

proc position* (s: Sound): float=
    var val: array[3, ALfloat]
    if s.src != 0:
        alSourcefv(s.src, AL_POSITION, val)
        echo val[0], " ", val[1], " ", val[2]
        return 0.0
    else:
        return 0.0

proc playbackPosition* (s: Sound): float=
    if s.src != 0:
        var val: ALfloat = 0.0
        alGetSourcef(s.src, AL_SEC_OFFSET, addr val)
        return val.float
    else:
        return 0.0

proc `playbackPosition=`* (s: Sound, val: float)=
    if s.src != 0:
        alSourcef(s.src, AL_SEC_OFFSET, val.ALfloat)

proc pause* (s: Sound)=
    if s.src != 0:
        alSourcePause(s.src)

proc resume* (s: Sound)=
    if s.src != 0:
        s.play()

proc paused* (s: Sound): bool=
    if s.src != 0:
        var val: ALint = 0
        alGetSourcei(s.src, AL_SOURCE_STATE, addr val)
        return
            if val != AL_PAUSED:
                false
            else:
                true
    else:
        return false
    
proc `paused=`* (s: Sound, val: bool)=
    if s.src != 0:
        if val:
            s.pause()
        else:
            s.resume()

proc `gain=`*(s: Sound, v: float) =
    s.mGain = v
    if s.src != 0:
        alSourcef(s.src, AL_GAIN, v)

proc gain*(s: Sound): float {.inline.} = s.mGain

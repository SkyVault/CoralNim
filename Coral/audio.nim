import os

import
    sound.private.sound_al

type 
    CoralAudioMixer* = ref object
    CoralAudio* = ref object
        sound: Sound
        playbackPosForPause: float

var
    audio_initialized = false

proc playbackPosition* (audio: CoralAudio): float
proc `playbackPosition=`* (audio: CoralAudio, val: float)

proc init* (audio: CoralAudioMixer)=
    audio_initialized = true

proc destroy* (audio: CoralAudioMixer)=
    destroyAllSounds()

proc loadAudio* (mixer: CoralAudioMixer, path: string) : CoralAudio=
    result = CoralAudio(playbackPosForPause : 0.0)
    result.sound = newSoundWithFile(path)

proc play* (audio: CoralAudio)=
    audio.sound.play()
    audio.playbackPosForPause = 0.0

proc stop* (audio: CoralAudio)=
    audio.sound.stop()
    audio.playbackPosForPause = 0.0

proc playing* (audio: CoralAudio): bool=
    # This isnt multiplatform :/
    return audio.sound.isPlaying

proc `volume=`* (audio: CoralAudio, v: float)=
    audio.sound.gain = v

proc volume* (audio: CoralAudio): auto = audio.sound.gain

proc paused* (audio: CoralAudio): bool=
    return audio.sound.paused

proc pause* (audio: CoralAudio)=
    audio.sound.pause()
    audio.playbackPosForPause = audio.playbackPosition

proc resume* (audio: CoralAudio)=
    audio.sound.resume()
    audio.playbackPosition = audio.playbackPosForPause

proc `paused=`* (audio: CoralAudio, val: bool)=
    if val: audio.pause()
    else: audio.resume()

proc togglePause* (audio: CoralAudio)=
    audio.paused = not audio.paused

proc `playing=`* (audio: CoralAudio, value: bool)=
    case value:
        of true: 
            if not audio.playing: 
                audio.play()
        of false: audio.stop()

proc playbackPosition* (audio: CoralAudio): float=
    return audio.sound.playbackPosition
    
proc `playbackPosition=`* (audio: CoralAudio, val: float)=
    audio.sound.playbackPosition = val
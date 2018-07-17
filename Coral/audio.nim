import os

import
    sound.private.sound_al

type 
    AudioMixer* = ref object
    Audio* = ref object
        sound: Sound
        playbackPosForPause: float

var
    audio_initialized = false

proc playbackPosition* (audio: Audio): float
proc `playbackPosition=`* (audio: Audio, val: float)

proc init* (audio: AudioMixer)=
    audio_initialized = true

proc destroy* (mixer: AudioMixer)=
    destroyAllSounds()

proc loadAudio* (mixer: AudioMixer, path: string) : Audio=
    result = Audio(playbackPosForPause : 0.0)
    result.sound = newSoundWithFile(path)

proc play* (audio: Audio)=
    audio.sound.play()
    audio.playbackPosForPause = 0.0

proc stop* (audio: Audio)=
    audio.sound.stop()
    audio.playbackPosForPause = 0.0

proc destroy* (audio: Audio)=
    audio.sound.destroy()

proc playing* (audio: Audio): bool=
    # This isnt multiplatform :/
    return audio.sound.isPlaying

proc `volume=`* (audio: Audio, v: float)=
    audio.sound.gain = v

proc volume* (audio: Audio): auto = audio.sound.gain

proc paused* (audio: Audio): bool=
    return audio.sound.paused

proc pause* (audio: Audio)=
    audio.sound.pause()
    audio.playbackPosForPause = audio.playbackPosition

proc resume* (audio: Audio)=
    audio.sound.resume()
    audio.playbackPosition = audio.playbackPosForPause

proc `paused=`* (audio: Audio, val: bool)=
    if val: audio.pause()
    else: audio.resume()

proc togglePause* (audio: Audio)=
    audio.paused = not audio.paused

proc looping* (audio: Audio): bool=
    # audio.sound.setLooping
    return audio.sound.looping

proc `looping=`* (audio: Audio, value: bool)=
    audio.sound.setLooping value

proc duration* (audio: Audio): float=
    return audio.sound.duration

proc `playing=`* (audio: Audio, value: bool)=
    case value:
        of true: 
            if not audio.playing: 
                audio.play()
        of false: audio.stop()

proc playbackPosition* (audio: Audio): float=
    return audio.sound.playbackPosition
    
proc `playbackPosition=`* (audio: Audio, val: float)=
    audio.sound.playbackPosition = val
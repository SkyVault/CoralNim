import os

import
    sound.sound

type 
    CoralAudioMixer* = ref object
    CoralAudio* = ref object
        sound: Sound

var
    audio_initialized = false

proc init* (audio: CoralAudioMixer)=
    audio_initialized = true

proc loadAudio* (mixer: CoralAudioMixer, path: string) : CoralAudio=
    result = CoralAudio()
    result.sound = newSoundWithFile(path)

proc play* (audio: CoralAudio)=
    audio.sound.play()

proc stop* (audio: CoralAudio)=
    audio.sound.stop()

proc playing* (audio: CoralAudio): bool=
    # This isnt multiplatform :/
    return audio.sound.isPlaying

proc `playing=`* (audio: CoralAudio, value: bool)=
    case value:
        of true: audio.play()
        of false: audio.stop()
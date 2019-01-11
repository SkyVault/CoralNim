import os
import
  ../../src/Coral,
  ../../src/Coralpkg/[platform, audio, art, input]

initGame(1280, 720, "audio")
initArt()

let path = joinPath(getAppDir(), "test.ogg")
echo path
let a = loadAudio path
a.looping = true
#a.play()

gameLoop:
  #echo "here"
  if Input.isKeyPressed(Key.Left):
    a.playbackPosition = a.playbackPosition - 4

  if Input.isKeyPressed(Key.Right):
    a.playbackPosition = a.playbackPosition + 4

  if Input.isKeyPressed(Key.Space):
    echo "here"
    #a.playing = not a.playing

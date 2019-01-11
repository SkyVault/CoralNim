import os, ospaths
import
  ../../src/Coral,
  ../../src/Coralpkg/[platform, audio, art, input]

import
  nim_tiled

initGame(1280, 720, "audio")
initArt()

let myMap = loadTiledMap joinPath(getAppDir(), "Dungeon_Room_2.tmx")

while updateGame():
  discard

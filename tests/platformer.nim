import
  ../src/Coral,
  ../src/Coralpkg/[cgl, platform, art, maths],
  math

const WorldMap = [
  [
    "........................",
    ".......................G",
    ".................11...11",
    "...........111...11...11",
    ".S........1111...11...11",
    "111111...11111...11...11",
    "111111...11111...11...11",
  ],

  [
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
  ],
]

const TileSize = 32

type
  Game = ref object
    currentLevel: int 

proc update(game: var Game)=
  discard

proc draw(game: var Game)=
  let level = WorldMap[game.currentLevel]
  let width = level[0].len
  let height = level.len

  for y in 0..<height:
    for x in 0..<width:
      let color = case level[y][x]:
      of '1':
        (0.8, 0.4, 0.2, 1.0)
      of 'G':
        (1.0, 0.9, 0.2, 1.0)
      else:
        (0.0, 0.0, 0.0, 0.0)
      setDrawColor color

      drawRect(x * TileSize, y * TileSize, TileSize, TileSize)

initGame(
  1280,
  720,
  "Coral: Platformer example",
  ContextSettings(majorVersion: 3, minorVersion: 3, core: true))
initArt()

var game = Game(
  currentLevel: 0,
  )

while updateGame():
  update(game)

  clearColorAndDepthBuffers (0.0, 0.0, 0.0, 1.0)

  beginArt()
  draw(game)
  flushArt()

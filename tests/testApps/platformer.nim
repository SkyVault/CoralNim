import
  ../../src/Coral,
  ../../src/Coralpkg/[cgl, platform, art, maths, ecs],
  sets,
  typetraits,
  typeinfo,
  options,
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
const EntitySize = 28

type
  Game = ref object
    currentLevel: int 

  BodyC = ref object of Component
    x, y, w, h: float

  SpriteC = ref object of Component
    test: string

initGame(
  1280,
  720,
  "Coral: Platformer example",
  ContextSettings(majorVersion: 3, minorVersion: 3, core: true))

initArt()
initEntityWorld()

var game = Game(
  currentLevel: 0,
  )

let player = World.createEntity()
player.add(BodyC(x: 0, y: 0, w: EntitySize, h: EntitySize))
player.add(SpriteC(test: "Hello"))

echo player.get(BodyC).w

var testSystem = System(
  entityIds: newSeq[EntityID](100),
  matchList: initSet[string](8))

testSystem.matchList.incl("BodyC")
testSystem.matchList.incl("Banana")

echo testSystem.matches player

proc update(game: var Game)=
  discard

proc draw(game: var Game)=
  let level = WorldMap[game.currentLevel]
  let width = level[0].len
  let height = level.len

  for y in 0..<height:
    for x in 0..<width:
      let color = case level[y][x]:
      of '1': (0.8, 0.4, 0.2, 1.0)
      of 'G': (1.0, 0.9, 0.2, 1.0)
      else: (0.0, 0.0, 0.0, 0.0)
      setDrawColor color

      drawRect(x * TileSize, y * TileSize, TileSize, TileSize)

  setDrawColor Green
  drawLineRect(100, 100, 200, 100, Time.timer, 100, 50)

  setDrawColor Blue
  drawCircle(100, 100, 32)

initGame(
  1280,
  720,
  "Coral: Platformer example",
  ContextSettings(majorVersion: 3, minorVersion: 3, core: true))
initArt()

var theGame = Game(
  currentLevel: 0,
  )

while updateGame():
  update(theGame)

  clearColorAndDepthBuffers (0.0, 0.0, 0.0, 1.0)

  beginArt()
  draw(theGame)
  flushArt()

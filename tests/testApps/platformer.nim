import
  ../../src/Coral,
  ../../src/Coralpkg/[cgl, platform, art, maths, ecs, input],
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
    "1..1.......111...11...11",
    "1S.1......1111...11...11",
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
const Gravity = 300.0

type
  Game = ref object
    currentLevel: int 

  BodyC = ref object of Component
    x, y, w, h: float

  SpriteC = ref object of Component
    test: string

  PhysicsC = ref object of Component
    vx, vy: float

  PlayerC = ref object of Component

var theGame = Game(
  currentLevel: 0,
  )

initGame(
  1280,
  720,
  "Coral: Platformer example",
  ContextSettings(majorVersion: 3, minorVersion: 3, core: true))

initArt()
initEntityWorld()

let player = World.createEntity()
player.add(BodyC(x: 0, y: 0, w: EntitySize, h: EntitySize))
player.add(SpriteC(test: "Hello"))
player.add(PhysicsC(vx: 0, vy: 0))
player.add(PlayerC())

system RenderSystem:
  match = [BodyC, SpriteC]

  proc draw(self: Entity)=
    let body = self.get(BodyC)
    let sprite = self.get(SpriteC)
    setDrawColor P8_Peach
    drawRect(body.x, body.y, body.w, body.h)

system PlayerSystem:
  match = [PlayerC, BodyC, PhysicsC]

  proc update(self: Entity)=
    let phys = self.get(PhysicsC)

    if Input.isKeyDown(Key.Left):
      phys.vx -= 100.0 * Time.deltaTime

    if Input.isKeyDown(Key.Right):
      phys.vx += 100.0 * Time.deltaTime

system PhysicsSystem:
  match = [BodyC, PhysicsC]

  proc update(self: Entity)=
    let phys = self.get(PhysicsC)
    let body = self.get(BodyC)

    phys.vy += Gravity * Time.deltaTime

    var nx = body.x + phys.vx * Time.deltaTime
    var ny = body.y + phys.vy * Time.deltaTime

    let left = math.floor(nx / TileSize).int
    let top = math.floor(ny / TileSize).int
    let bottom = math.floor((ny + body.h) / TileSize).int
    let right = math.floor((nx + body.w) / TileSize).int

    let currLevel = WorldMap[theGame.currentLevel]
    
    if left >= 0 and right <= WorldMap[theGame.currentLevel][0].len - 1 and
      top >= 0 and bottom <= WorldMap[theGame.currentLevel].len - 1:

      let X = math.floor(body.x / TileSize).int
      let Y = math.floor(body.y / TileSize).int
      
      # Handle Y
      
      # Down 
      
      if currLevel[bottom][X] != '.':
        ny = body.y
        phys.vy = 0.0

      # Handle X
      if currLevel[Y][right] != '.':
        nx = body.x

      if currLevel[Y][left] != '.':
        nx = body.x

      discard

    body.x = nx
    body.y = ny

    phys.vx *= math.pow(0.002, Time.deltaTime)
    phys.vy *= math.pow(0.002, Time.deltaTime)

  proc draw(self: Entity)=
    let phys = self.get(PhysicsC)
    let body = self.get(BodyC)
    
    setDrawColor(Red)
    drawLine(
      body.x + body.w / 2,
      body.y + body.h / 2,
      body.x + body.w / 2 + phys.vx,
      body.y + body.h / 2)

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

initGame(
  1280,
  720,
  "Coral: Platformer example",
  ContextSettings(majorVersion: 3, minorVersion: 3, core: true))
initArt()

while updateGame():
  update(theGame)

  clearColorAndDepthBuffers (0.0, 0.0, 0.0, 1.0)

  beginArt()
  draw(theGame)
  flushArt()

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
const Gravity = 1200.0

type
  Game = ref object
    currentLevel: int 

  BodyC = ref object of Component
    x, y, w, h: float

  SpriteC = ref object of Component
    test: string

  PhysicsC = ref object of Component
    vx, vy, gravScale: float
    onGround: bool

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
player.add(PhysicsC(vx: 0, vy: 0, gravScale: 1.0, onGround: false))
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
    const Speed = 300

    if Input.isKeyDown(Key.Left):
      phys.vx -= Speed * Time.deltaTime

    if Input.isKeyDown(Key.Right):
      phys.vx += Speed * Time.deltaTime

    if Input.isKeyDown(Key.Space) and phys.onGround:
      phys.vy = -Gravity * 0.5
      phys.gravScale = 1.5 

system PhysicsSystem:
  match = [BodyC, PhysicsC]

  proc update(self: Entity)=
    let phys = self.get(PhysicsC)
    let body = self.get(BodyC)

    phys.vy += (Gravity * (1-phys.gravScale)) * Time.deltaTime

    var nx = body.x + phys.vx * Time.deltaTime
    var ny = body.y + phys.vy * Time.deltaTime

    let left = math.floor(nx / TileSize).int
    let top = math.floor(ny / TileSize).int
    let bottom = math.floor((ny + body.h) / TileSize).int
    let right = math.floor((nx + body.w) / TileSize).int

    let currLevel = WorldMap[theGame.currentLevel]

    proc getTile(x, y: int):char=
        if x < 0 or y < 0 or x > currLevel[0].len or y > currLevel.len:
            return '.'
        else:
            return currLevel[y][x]
    
    let tile_bottom = getTile(left, bottom)
    let tile_right = getTile(right, top)
    let tile_left = getTile(left, top)

    phys.onGround = false
    phys.gravScale *= math.pow(0.2, Time.deltaTime)
    echo phys.gravScale

    if tile_bottom != '.' and tile_bottom != 'S':
      ny = (TileSize * bottom.float) - body.h
      phys.onGround = true

    if tile_right != '.' and tile_right != 'S':
      nx = body.x

    if tile_left != '.' and tile_left != 'S':
      nx = body.x

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
  endArt()

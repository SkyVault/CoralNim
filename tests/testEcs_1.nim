import ../src/Coralpkg/[ecs]
import sets
import macros

type
  BodyC = ref object of Component
    x, y, w, h: float

  SpriteC = ref object of Component
    test: string

initEntityWorld()

let player = World.createEntity()
player.add BodyC(x: 0, y: 0, w: 100, h: 123)
player.add SpriteC(test: "Banana")

assert(player.get(BodyC).h == 123)

let sys = System(
    entityIds: newSeq[EntityID](100),
    matchList: initSet[string](8)
  )

assert(sys.matches(player) == false)
sys.matchList.incl "BodyC"
assert(sys.matches(player) == true)
sys.matchList.incl "Banana"
assert(sys.matches(player) == false)

#dumpTree:
#  MySystem.load = proc(sys: System, self: Entity)=
#    discard

expandMacros:
  system MySystem:
    match = [BodyC, Sprite]

    proc load(self: Entity)=
      let body = self.get(BodyC)
      echo body.x

    proc update(self: Entity)=
      discard

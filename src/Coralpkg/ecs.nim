import options, sets
import typetraits, tables
import macros

type EntityID* = distinct int

const EntityBlockSize = 256

type
  Component* = ref object of RootObj

  Entity* = ref object
    uniqueId: int
    id: EntityID
    loaded: bool
    components: Table[string, Component]

    update*: proc(self: Entity)
    draw*: proc(self: Entity)

  System* = ref object
    ## TODO(Dustin): @Private
    entityIds*: seq[EntityID]
    matchList*: HashSet[string]

    load*: proc(sys: System, self: Entity)
    update*: proc(sys: System, self: Entity)
    draw*: proc(sys: System, self: Entity)
    destroy*: proc(sys: System, self: Entity)

  EntityWorld* = ref object
    entities: seq[Option[Entity]]

## Entity Functions
proc add* [T](entity: Entity, component: T)=

  if entity.components.hasKey(T.name):
    echo "Entity already contains the component: ", T.name
    return

  entity.components.add T.name, component

proc get* (entity: Entity, T: typedesc): T=

  if entity.components.hasKey(T.name):
    return cast[T](entity.components[T.name])

  echo "Entity does not have the component: ", T.name
  return nil

proc entityDefaultUpdate* (entity: Entity)= discard
proc entityDefaultDraw* (entity: Entity)= discard

## System Functions

proc systemDefaultLoad* (sys: System,self: Entity)= discard
proc systemDefaultUpdate* (sys: System, self: Entity)= discard
proc systemDefaultDraw* (sys: System, self: Entity)= discard
proc systemDefaultDestroy* (sys: System, self: Entity)= discard

proc newSystem* (): System=
  result = System(
      entityIds: newSeq[EntityID](100),
      matchList: initSet[string](8))

static:
  echo treeRepr parseStmt(
    """
    system MySystem:
      match = [BodyC, Sprite]

      proc init(self: Entity)=
        discard
    """
  )

macro system* (head, body: untyped):untyped =
  result = newStmtList()
  discard """
    StmtList
      Command
        Ident "system"
        Ident "MySystem"
        StmtList
          Call
            Ident "match"
            StmtList
              Bracket
                Ident "BodyC"
                Ident "Sprite"
          ProcDef
            Ident "init"
            Empty
            Empty
            FormalParams
              Empty
              IdentDefs
                Ident "self"
                Ident "Entity"
                Empty
            Empty
            Empty
            StmtList
              DiscardStmt
                Empty
  """

  let identName = head.strVal

  result.add(newVarStmt(ident(identName),
    newCall("newSystem")))

  for child in head.children:
    echo("head -->", child.kind)

  for child in body.children:
    echo("body -->", child.kind)


proc matches* (sys: System, ent: Entity):bool =
  result = true
  if sys.matchList.len == 0: return false
  for comp in sys.matchList:
    if not ent.components.hasKey comp:
      return false

## EntityWorld Functions
var world: EntityWorld = nil
var uuid = 0

template World* (): auto= ecs.world

proc initEntityWorld* () =
  world = EntityWorld(
    entities: newSeq[Option[Entity]](EntityBlockSize)
  )

proc findSpace(world: EntityWorld): EntityID=
  for i in 0..<world.entities.len:
    if world.entities[i] == none(Entity):
      return (EntityID)i
  return (EntityID)(-1)

proc createEntity* (world: EntityWorld, components: varargs[Component]): Entity {.discardable.}=
  var space = findSpace(world).int
  if space == -1:
    # Grow
    space = world.entities.len
    world.entities.setLen(world.entities.len() * 2)

  var entity = Entity(
    uniqueId: uuid,
    id: (EntityID)space,
    loaded: false,
    components: initTable[string, Component](),

    update: entityDefaultUpdate,
    draw: entityDefaultDraw
  )

  for c in components:
    entity.add(c)

  inc uuid

  world.entities[space] = some(entity)

  return entity

proc getEntity* (world: EntityWorld, id: EntityID): Option[Entity] =
  if world == nil:
    echo "Error:: Entity world has not been initialized"
    return none(Entity)

  if id.int >= int(len world.entities):
    return none(Entity)
  if id.int < 0:
    return none(Entity)

  return world.entities[(id.int)]

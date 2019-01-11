import options, sets
import typetraits, tables
import macros
import strformat

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

      proc load(self: Entity)=
        discard

      proc update(self: Entity)=
        discard
    """
  )

# TODO make it so that the user does not require the sys parameter

macro system* (head, body: untyped):untyped =
  result = newStmtList()

  let identName = head.strVal

  result.add(newVarStmt(ident(identName),
    newCall("newSystem")))

  # TODO(Dustin): Replace assert with proc 
  
  proc errorIf(expr: bool, msg: string)=
    if expr: error(msg)

  for child in body.children:
    case child.kind:
    of nnkAsgn:
      let ident = child[0]
      let list = child[1]
      errorIf(list.kind != nnkBracket, &"{ident} expects a bracketed list of component types for system {identName}")

      case ident.strVal:
      of "match":
        for val in list.children:
          errorIf(val.kind != nnkIdent, &"{ident} expects a bracketed list of component types, but got {val.kind}")
          let name = val.strVal
          result.add(newCall(
            "incl",
            newDotExpr(ident(identName), ident("matchList")),
            newStrLitNode(name)
          ))

      else:
        errorIf(true, &"Unknown list type {ident.strVal} for system {identName}")

    of nnkProcDef:
      let ident = child[0]
    
      case ident.strVal:
      of "load", "update", "draw":

        child.params.insert(1, newIdentDefs(ident("sys"), ident("System")))

        var arr = newSeq[NimNode]()
        for param in child.params:
          arr.add(param)

        result.add(
          newAssignment(
            newDotExpr(ident(identName), ident),
            newProc(
              procType=nnkLambda,
              params=arr,
              body=child[6]
            )))
      else:
        errorIf(true, &"Unknown method {ident.strVal} for system {identName}")

    else:
      echo child.kind

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

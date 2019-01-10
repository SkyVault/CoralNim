import options

type EntityID = distinct int

const EntityBlockSize = 256

type
  Component = ref object of RootObj

  Entity = ref object
    uniqueId: int
    id: EntityID

  System = ref object

  EntityWorld = ref object
    entities: seq[Option[Entity]]

## Entity Functions


## System Functions


## EntityWorld Functions 
var world: EntityWorld = nil
proc initEntityWorld* () =
  world = EntityWorld(
    entities: newSeq[Option[Entity]](EntityBlockSize)
  )

proc findSpace(world: EntityWorld): EntityID=
  for i in 0..<world.entities.len:
    if world.entities[i] == none(Entity):
      return (EntityID)i
  return (EntityID)(-1)

proc createEntity* (world: EntityWorld): Entity=
  var space = findSpace(world).int
  if space == -1:
    # Grow
    space = world.entities.len
    world.entities.setLen(world.entities.len() * 2)

  var entity = Entity()

  world.entities[space] = some(entity)

proc getEntity* (world: EntityWorld, id: EntityID): Option[Entity] =
  if world == nil:
    echo "Error:: Entity world has not been initialized"
    return none(Entity)

  if id.int >= int(len world.entities):
    return none(Entity)
  if id.int < 0:
    return none(Entity)

  return world.entities[(id.int)]
  

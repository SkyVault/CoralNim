import 
    tables,
    sequtils,
    typetraits

type
    CoralComponent* = ref object of RootObj

    CoralEntity* = ref object
        loaded, remove: bool
        components: Table[string, CoralComponent]

    CoralSystem* = ref object
        worldRef: CoralWorld
        matchList: seq[string]

        preUpdate:  proc(s: CoralSystem)
        load:       proc(s: CoralSystem, e: CoralEntity)
        update:     proc(s: CoralSystem, e: CoralEntity)
        draw:     proc(s: CoralSystem, e: CoralEntity)
        destroy:    proc(s: CoralSystem, e: CoralEntity)

    CoralWorld* = ref object
        entities: seq[CoralEntity]
        systems: seq[CoralSystem]

proc default_load         (s: CoralSystem, e: CoralEntity) = discard
proc default_preUpdate    (s: CoralSystem)                 = discard
proc default_update       (s: CoralSystem, e: CoralEntity) = discard
proc default_render       (s: CoralSystem, e: CoralEntity) = discard
proc default_destroy      (s: CoralSystem, e: CoralEntity) = discard

proc add* [T](self: CoralEntity, component: T): T {.discardable.} =
    self.components.add(T.name, component)
    return component.T

proc get* (self: CoralEntity, T: typedesc): T =
    return cast[T](self.components[T.name])

proc has* (self: CoralEntity, T: typedesc): bool=
    return self.components.hasKey(T.name)

proc has* (self: CoralEntity, t: string): bool=
    return self.components.hasKey(t)

proc newSystem(
    matchlist: seq[string], 
    load:       proc(s: CoralSystem, e: CoralEntity),
    preUpdate:  proc(s: CoralSystem)                ,
    update:     proc(s: CoralSystem, e: CoralEntity),
    draw:     proc(s: CoralSystem, e: CoralEntity),
    destroy:    proc(s: CoralSystem, e: CoralEntity)
    ): CoralSystem=

    var match = newSeq[string]()
    for m in matchlist:
        match.add(m)
    
    return CoralSystem(
        matchList: match,
        load: load,
        preUpdate: preUpdate,
        update: update,
        draw: draw,
        destroy: destroy
    )

proc matches(s: CoralSystem, e: CoralEntity): bool=
    for m in s.matchList:
        if not e.has(m): return false
    return true

proc newCoralWorld* (): CoralWorld=
    CoralWorld(
        entities: newSeq[CoralEntity](),
        systems: newSeq[CoralSystem]()
    )

proc update* (world: CoralWorld)=
    let num = world.entities.len
    for i in countdown(num - 1, 0):
        let entity = world.entities[i]

        for system in world.systems:
            if system.matches entity:
                if not entity.loaded:
                    system.load(system, entity)

                system.update(system, entity)

        entity.loaded = true
        if entity.remove:
            for system in world.systems:
                if system.matches entity:
                    system.destroy(system, entity)
            world.entities.delete(i)

proc draw* (world: CoralWorld)=
    for entity in world.entities:
        for system in world.systems:
            if system.matches entity:
                system.draw(system, entity)

proc createEntity* (world: CoralWorld, components: seq[CoralComponent] = @[]): auto {.discardable.}=
    result = CoralEntity(
        components: initTable[string, CoralComponent](),
        loaded: false,
        remove: false
    )

    for c in components:
        result.add(c)
        
    world.entities.add result

proc createSystem* (
    world: CoralWorld, 
    matchlist: seq[string], 
    load: proc(s: CoralSystem, e: CoralEntity) = default_load,
    preUpdate: proc(s: CoralSystem) = default_preUpdate,
    update: proc(s: CoralSystem, e: CoralEntity) = default_update,
    draw: proc(s: CoralSystem, e: CoralEntity) = default_render,
    destroy: proc(s: CoralSystem, e: CoralEntity) = default_destroy
    ): CoralSystem {.discardable.}=

    result = newSystem(
        matchlist,
        load,
        preUpdate,
        update,
        draw,
        destroy
    )

    world.systems.add result
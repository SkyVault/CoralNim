import 
    tables,
    sequtils,
    typetraits

type
    Component* = ref object of RootObj

    Entity* = ref object
        loaded, remove: bool
        components: Table[string, Component]

    System* = ref object
        worldRef: World
        matchList: seq[string]

        preUpdate:  proc(s: System)
        load:       proc(s: System, e: Entity)
        update:     proc(s: System, e: Entity)
        preDraw:    proc(s: System)
        draw:     proc(s: System, e: Entity)
        destroy:    proc(s: System, e: Entity)

    World* = ref object
        entities: seq[Entity]
        systems: seq[System]

proc default_load         (s: System, e: Entity) = discard
proc default_preUpdate    (s: System)                 = discard
proc default_update       (s: System, e: Entity) = discard
proc default_preRender    (s: System) = discard
proc default_render       (s: System, e: Entity) = discard
proc default_destroy      (s: System, e: Entity) = discard

proc add* [T](self: Entity, component: T): T {.discardable.} =
    self.components.add(T.name, component)
    return component

proc get* (self: Entity, T: typedesc): T =
    return cast[T](self.components[T.name])

proc has* (self: Entity, T: typedesc): bool=
    return self.components.hasKey(T.name)

proc has* (self: Entity, t: string): bool=
    return self.components.hasKey(t)

proc newSystem(
    matchlist: seq[string], 
    load:       proc(s: System, e: Entity),
    preUpdate:  proc(s: System)                ,
    update:     proc(s: System, e: Entity),
    preDraw:    proc(s: System),
    draw:     proc(s: System, e: Entity),
    destroy:    proc(s: System, e: Entity)
    ): System=

    var match = newSeq[string]()
    for m in matchlist:
        match.add(m)
    
    return System(
        matchList: match,
        load: load,
        preUpdate: preUpdate,
        update: update,
        preDraw: preDraw,
        draw: draw,
        destroy: destroy
    )

proc matches(s: System, e: Entity): bool=
    for m in s.matchList:
        if not e.has(m): return false
    return true

proc newWorld* (): World=
    World(
        entities: newSeq[Entity](),
        systems: newSeq[System]()
    )

proc update* (world: World)=
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

proc draw* (world: World)=
    for entity in world.entities:
        for system in world.systems:
            if system.matches entity:
                system.draw(system, entity)

proc createEntity* (world: World, components: seq[Component] = @[]): auto {.discardable.}=
    result = Entity(
        components: initTable[string, Component](),
        loaded: false,
        remove: false
    )

    for c in components:
        result.add(c)
        
    world.entities.add result

proc createSystem* (
    world: World, 
    matchlist: seq[string], 
    load: proc(s: System, e: Entity) = default_load,
    preUpdate: proc(s: System) = default_preUpdate,
    update: proc(s: System, e: Entity) = default_update,
    preDraw: proc(s: System) = default_preRender,
    draw: proc(s: System, e: Entity) = default_render,
    destroy: proc(s: System, e: Entity) = default_destroy
    ): System {.discardable.}=

    result = newSystem(
        matchlist,
        load,
        preUpdate,
        update,
        preDraw,
        draw,
        destroy
    )

    world.systems.add result
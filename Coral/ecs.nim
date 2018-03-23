import 
    tables,
    typetraits

type
    CoralComponent* = ref object of RootObj

    CoralEntity* = ref object
        components: TableRef[string, CoralComponent]

    CoralSystem* = ref object
    CoralWorld* = ref object

proc add* [T](self: CoralEntity, component: T): T {.discardable.} =
    self.components.add(type(T).name, component)
    return component.T

proc get* (self: CoralEntity, id: string): CoralComponent=
    return self.components[id]

proc perseErnerm* [T: enum](s: string):T =
    for e in low(T)..high(T):
        return e
    return nil

proc newWorld* (): CoralWorld=
    CoralWorld()

proc create* (world: CoralWorld): auto=
    return CoralEntity(
        components: newTable[string, CoralComponent]()
    )
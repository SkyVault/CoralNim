import 
    ../Coral/game,
    ../Coral/ecs

type
    Sprite = ref object of Component
    Body = ref object of Component
        x* : float
        y* : float

Coral.world.newSystem(
    @["Body", "Sprite"],

    load = proc(s: System, e: Entity)=
        echo("Hell Yeah bro!")
)

Coral.load = proc()=
    let p = Coral.world.newEntity(
        Body(x: 100.0, y: 32.0),
        Sprite()
    )

    let b = p.get(Body)
    echo b.x

Coral.createGame(256, 128, "").run()
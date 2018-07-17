import 
    ../Coral/game,
    ../Coral/ecs

Coral.world.createSystem(
    @["Body", "Paddle"],

    load = proc(s: System, e: Entity)=
        echo("Hell Yeah bro!")
)
import 
    ../Coral/game,
    ../Coral/ecs

Coral.world.createSystem(
    @["Body", "Paddle"],

    load = proc(s: CoralSystem, e: CoralEntity)=
        echo("Hell Yeah bro!")
)
import 
    ../Coral/game,
    ../Coral/ecs

proc createSystems* (game: CoralGame)=
    game.world.createSystem(
        @["Body", "Paddle"],

        load = proc(s: CoralSystem, e: CoralEntity)=
            echo("Matched dude!")
    )
import
    ../Coral/game,
    ../Coral/graphics,
    ../Coral/renderer,
    ../Coral/gameMath,
    ../Coral/ecs,
    ../Coral/audio,
    random,
    test,
    os,
    math

type 
    Entity = ref object of RootObj
        position*, size*: V2
        velocity*: V2
        color*: Color
        friction* :float
        delete: bool

    Brick   = ref object of Entity
    Paddle  = ref object of Entity
    Ball    = ref object of Entity

proc absf(v: float): float=
    if v < 0: return -v
    else: return v

method update(self: Entity){.base.} = discard
method collision(self: Entity, other: Entity){.base.} = discard

proc updatePhysics(self: Entity)=
    self.position.x += self.velocity.x * Coral.clock.dt
    self.position.y += self.velocity.y * Coral.clock.dt
    self.velocity *= math.pow(self.friction, Coral.clock.dt)

var entities = newSeq[Entity]()

method update(self: Paddle)=
    const SPEED = 200

    if Coral.isKeyDown CoralKey.Left:
        self.velocity.x = -SPEED

    if Coral.isKeyDown CoralKey.Right:
        self.velocity.x = +SPEED

method update(self: Ball)=
    if self.position.x < 0:
        self.velocity.x = absf(self.velocity.x)

    if self.position.x > Coral.windowSize[0].float - self.size.x:
        self.velocity.x = -absf(self.velocity.x)

    if self.position.y < 0:
        self.velocity.y = absf(self.velocity.y)

    if self.position.y > Coral.windowSize[1].float - self.size.y:
        self.velocity.y = absf(self.velocity.y)

method collision(self: Ball, other: Entity)=
    if other of Paddle:
        self.velocity.y *= -1
        self.velocity.x += other.velocity.x * 0.2
    
    if other of Brick:
        other.delete = true
        self.velocity.y *= -1

Coral.load = proc()=
    const MARGIN = 8

    let ball_vel_x = random(100.0) - 200.0
    let ball_vel_y = random(100.0) - 200.0

    entities.add(
        Ball(
            position: newV2(
                Coral.windowSize[0].float / 2.0 - 16.0 / 2.0,
                Coral.windowSize[1].float / 2.0 - 16.0 / 2.0
            ),
            friction: 1.0,
            delete: false,
            size: newV2(16, 16),
            velocity: newV2(ball_vel_x, ball_vel_y),
            color: P8Orange
        )
    )

    entities.add(
        Paddle(
            position: newV2(
                Coral.windowSize[0].float / 2.0 - 128.0 / 2.0, 
                Coral.windowSize[1].float - 128.0
            ),
            friction: 0.01,
            size: newV2(128, 16),
            delete: false,
            velocity: newV2(),
            color: P8Indigo
        )
    )

    for y in 0 .. 3:
        for x in 0 .. 10:
            entities.add(
                Brick(
                    position: newV2((32 + MARGIN) * x, (16 + MARGIN) * y),
                    size: newV2(32, 16),
                    velocity: newV2(),
                    delete: false,
                    friction: 0.0,
                    color: case y:
                            of 0: P8Red
                            of 1: P8Green
                            of 2: P8Blue
                            else: P8Pink
                )
            )

Coral.update = proc()=
    Coral.windowTitle = "カウボーイビバップカウボーイビバップ  :: " & $Coral.clock.averageFps

    if Coral.isKeyReleased CoralKey.Escape:
        quit(Coral)

    for i in countdown(entities.len - 1, 0):
        let entity = entities[i]

        for other in entities:
            if other == entity: continue

            let phy_pos = entity.position + entity.velocity * Coral.clock.dt

            if phy_pos.x + entity.size.x > other.position.x and
               phy_pos.x < other.position.x + other.size.x and
               phy_pos.y + entity.size.y > other.position.y and
               phy_pos.y < other.position.y + other.size.y:
                entity.collision(other)

        entity.update()
        entity.updatePhysics()

        if entity.delete:
            entities.delete(i)

Coral.render = proc()= 
    Coral.r2d.setBackgroundColor(P8Peach)

    for entity in entities:
        Coral.r2d.drawRect(
            entity.position,
            entity.size,
            0.0,
            entity.color
        )

Coral.createGame(11 * (32 + 8), 720, "Breakout!", config()).run()

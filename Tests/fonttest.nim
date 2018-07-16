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

var font: Font

Coral.load = proc()= 
    font = CoralLoadFont(getApplicationDir() & "/arial.ttf", 60)

Coral.draw = proc()=
    Coral.r2d.setBackgroundColor(P8Indigo)

    Coral.r2d.drawRect(0.0, 0.0, 100, 100, 0.0, P8Peach)
    # Coral.r2d.drawImage(font.image, newV2(0, font.image.height), newV2(font.image.width, -font.image.height), 0.0, newColor())

    let g = font.getChar '@'
    let t = Image(
        id: g.texture_id,
        width: g.size.x.int,
        height: g.size.y.int
    )
    Coral.r2d.drawImage(t, newV2(100, 100), newV2(t.width, t.height), 0.0, newColor())

    Coral.r2d.drawString(font, "Lorum Ipsum", newV2(25.0, 25.0))
    Coral.r2d.drawString(font, "Hello my mellow fellow!", newV2(100, 100))

Coral.createGame(1280, 720, "Font Test", config()).run()
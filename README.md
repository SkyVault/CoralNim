# Coral Framework

## Simple 2d game development platform for the Nim programming language (Warning) This framework is under heavy development

## Getting Started

```nim
import
    Coral/game,
    Coral/graphics,
    Coral/renderer

Coral.render = proc()=
    Coral.r2d.drawRect(100, 100, 100, 100, 45.0, Red)

Coral.createGame(800, 600, "My Coral Game", config())
    .run()
```
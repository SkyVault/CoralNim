# Design of the API

## Different modules

### GAME MODULE

1. Contains the input handler
2. Scene manager
3. Window creation and management

#### API
```nim
proc createWindow(size: (int, int), title: string, CoralWindowSettings settings = nil)
```


### GAME MATH MODULE

1. Contains vector maths and matrix maths for games
2. Simple lerp functions and stuff

### Graphics

1. Contains the main renderer for the framework
2. Color tools? though we could just use std color
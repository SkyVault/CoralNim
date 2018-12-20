# Package

version       = "0.0.1"
author        = "skyvault"
description   = "Coral 2d framework for nim"
license       = "MIT"
srcDir        = "src"
bin           = @["Coral"]

# Dependencies

requires "nim >= 0.18.0"
# requires "sdl2_nim"
requires "nim-glfw"
requires "nim-tiled"
requires "opengl"
requires "https://github.com/oprypin/nim-random"
requires "https://github.com/define-private-public/stb_image-Nim"

# Main Renderer for the Coral frame work
import
  sequtils,
  opengl,
  sdl2/[sdl]

type
  Vertex* = ref object
    position*: (float, float)

  Renderer* = ref object
    vertices: seq[Vertex]

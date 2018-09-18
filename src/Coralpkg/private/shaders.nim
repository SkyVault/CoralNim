## IMAGES

const VERTEX_SHADER* ="""
#version 330 core
layout (location = 0) in vec3 Vertices;

void main(void) {
  gl_Position = vec4(Vertices, 1.0); 
}
"""

const FRAGMENT_SHADER* ="""
#version 330 core
out vec4 Result; 

void main(void) {
  Result = vec4(1.0, 0.5, 0.0, 1.0);
}
"""

## PRIMITIVES

const PRIM_VERTEX_SHADER* ="""
#version 330 core
layout (location = 0) in vec3 Vertices;
layout (location = 1) in vec4 Colors;

out vec4 color;

uniform mat4 projection;

void main(void) {
  color = Colors;
  gl_Position = projection * vec4(Vertices, 1.0); 
}
"""

const PRIM_FRAGMENT_SHADER* ="""
#version 330 core
out vec4 Result; 

in vec4 color;

void main(void) {
  Result = color;
//Result = vec4(1.0, 1.0, 1.0, 1.0);
}
"""


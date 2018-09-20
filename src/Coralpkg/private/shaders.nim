## IMAGES

const VERTEX_SHADER* ="""
#version 330 core
layout (location = 0) in vec2 Vertices;

out vec2 uvs;

uniform vec4 region = vec4(0, 0, 1, 1);
uniform vec4 body; // x y w h
uniform vec2 transform = vec2(0, 0); // rot depth

uniform mat4 projection;

void main(void) {
  uvs = Vertices;
  uvs.y = 1 - uvs.y;

  uvs.x = (region.x + (uvs.x * region.z));
  uvs.y = (region.y + (uvs.y * region.w));

  float s = sin(-transform.x);
  float c = cos(-transform.x);

  mat2 rot = mat2(c, -s, s, c);

  vec2 pos = body.xy + (body.zw * ((rot * Vertices.xy) + 0.5));

  gl_Position = projection * vec4(pos, 0.0, 1.0); 
}
"""

const FRAGMENT_SHADER* ="""
#version 330 core

in vec2 uvs;

out vec4 Result; 

uniform sampler2D image;

void main(void) {
  vec4 sample = texture(image, uvs);
  Result = sample;
//Result = vec4(1, 1, 1, 1);
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
}
"""


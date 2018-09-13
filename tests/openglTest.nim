import
  ../src/Coral,
  ../src/Coralpkg/[cgl, platform, art],
  opengl,
  math

initGame(1280, 720, ":)", ContextSettings(majorVersion: 3, minorVersion: 3, core: true))

art.init()

while updateGame():
  glDisable(GL_CULL_FACE)

  clearColorAndDepthBuffers (0.1, 0.1, 0.1, 1.0)

  art.flush()

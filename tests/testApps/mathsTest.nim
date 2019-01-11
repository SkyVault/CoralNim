import
  ../../src/Coralpkg/maths

var
  a: Vec2 = newVec2(1.0, 2.0)
  b: Vec2 = newVec2(2.0, 3.0)

doAssert(a + b == newVec2(3, 5))
doAssert(a - b == newVec2(-1.0, -1.0))

a += b
b += a

a.x += 2.0

doAssert(a == newVec2(5, 5))

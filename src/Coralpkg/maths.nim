import
    math,
    strformat

type
    Vec3* = ref object
        ## 3 unit vector type
        x* , y* , z* : float32

    Vec2* = ref object
        ## 2 unit vector type
        x*, y*: float32

    Mat4Arr = object
        m00*, m10*, m20*, m30*: float32
        m01*, m11*, m21*, m31*: float32
        m02*, m12*, m22*, m32*: float32
        m03*, m13*, m23*, m33*: float32

    Mat4* = object {.union.}
        m* : array[16, float32]
        a* : Mat4Arr

    Mat3Arr = object
        m00*, m10*, m20*: float32
        m01*, m11*, m21*: float32
        m02*, m12*, m22*: float32

    Mat3* = object {.union.}
        m* : array[9, float32]
        a* : Mat3Arr

    Mat2Arr = object
        m00*, m10*: float32
        m01*, m11*: float32

    Mat2* = object {.union.}
        m* : array[4, float32]
        a* : Mat2Arr

const DEGTORAD* = PI / 180.0
const RADTODEG* = 180.0 / PI

proc newVec3* (x: float = 0, y: float = 0, z: float = 0): Vec3=
    Vec3(x: x, y: y, z: z)

proc Vec3Up*     (): Vec3 =
    ## Returns a zeroed vector with the y coordinate set to one
    newVec3(0, 1, 0)

proc Vec3Right*  (): Vec3 =
    newVec3(1, 0, 0)

proc Vec3Left*   (): Vec3 =
    newVec3(-1, 0, 0)

proc Vec3One*    (): Vec3 =
    newVec3(1, 1, 1)

proc `+`* (a: Vec3, b: Vec3): Vec3= newVec3(a.x + b.x, a.y + b.y, a.z + b.z)
proc `-`* (a: Vec3, b: Vec3): Vec3= newVec3(a.x - b.x, a.y - b.y, a.z - b.z)
proc `*`* (a: Vec3, b: Vec3): Vec3= newVec3(a.x * b.x, a.y * b.y, a.z * b.z)
proc `/`* (a: Vec3, b: Vec3): Vec3= newVec3(a.x / b.x, a.y / b.y, a.z / b.z)
proc `+`* (a: Vec3, b: float32): Vec3= newVec3(a.x + b, a.y + b, a.z + b)
proc `-`* (a: Vec3, b: float32): Vec3= newVec3(a.x - b, a.y - b, a.z - b)
proc `*`* (a: Vec3, b: float32): Vec3= newVec3(a.x * b, a.y * b, a.z * b)
proc `/`* (a: Vec3, b: float32): Vec3= newVec3(a.x / b, a.y / b, a.z / b)

proc `+=`* (a: Vec3, b: Vec3)= a.x += b.x; a.y += b.y; a.z += b.z
proc `-=`* (a: Vec3, b: Vec3)= a.x -= b.x; a.y -= b.y; a.z -= b.z
proc `*=`* (a: Vec3, b: Vec3)= a.x *= b.x; a.y *= b.y; a.z *= b.z
proc `/=`* (a: Vec3, b: Vec3)= a.x /= b.x; a.y /= b.y; a.z /= b.z
proc `+=`* (a: Vec3, b: float32)= a.x += b; a.y += b; a.z += b
proc `-=`* (a: Vec3, b: float32)= a.x -= b; a.y -= b; a.z -= b
proc `*=`* (a: Vec3, b: float32)= a.x *= b; a.y *= b; a.z *= b
proc `/=`* (a: Vec3, b: float32)= a.x /= b; a.y /= b; a.z /= b
proc `-`* (v: Vec3): Vec3 = v * -1

proc `==`* (a: Vec3, b: Vec3): bool=
    return a.x == b.x and a.y == b.y and a.z == b.z

proc move* (a: Vec3, by: Vec3)=
    a.x += by.x; a.y += by.y; a.z += by.z;

proc length* (a: Vec3): float32=
    sqrt((a.x * a.x) + (a.y * a.y) + (a.z * a.z))

proc normalize* (v: Vec3): Vec3 =
    let len = v.length()
    if len > 0: return newVec3(v.x / len, v.y / len, v.z / len)
    else: return newVec3(0, 0, 0)

proc dot* (a: Vec3, b: Vec3): float32=
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z)

proc cross* (a: Vec3, b: Vec3): Vec3 =
    newVec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )

proc angleBetween* (a: Vec3, b: Vec3): float32=
    return arccos(dot(a, b) / (a.length() * b.length()))

# v2
proc newVec2* (x: float = 0, y: float = 0): Vec2=
    Vec2(x: x, y: y)

proc newVec2* [T](x: T= 0, y: T= 0): Vec2=
    Vec2(x: (float32)x, y: (float32)y)

proc toVec3*     (v: Vec2): Vec3 = newVec3(v.x, v.y, 0)
proc Vec2Up*     (): Vec2 = newVec2(0, 1)
proc Vec2Right*  (): Vec2 = newVec2(1, 0)
proc Vec2Left*   (): Vec2 = newVec2(-1, 0)
proc Vec2One*    (): Vec2 = newVec2(1, 1)

proc `+`* (a: Vec2, b: Vec2): Vec2= newVec2(a.x + b.x, a.y + b.y)
proc `-`* (a: Vec2, b: Vec2): Vec2= newVec2(a.x - b.x, a.y - b.y)
proc `*`* (a: Vec2, b: Vec2): Vec2= newVec2(a.x * b.x, a.y * b.y)
proc `/`* (a: Vec2, b: Vec2): Vec2= newVec2(a.x / b.x, a.y / b.y)
proc `+`* (a: Vec2, b: float32): Vec2= newVec2(a.x + b, a.y + b)
proc `-`* (a: Vec2, b: float32): Vec2= newVec2(a.x - b, a.y - b)
proc `*`* (a: Vec2, b: float32): Vec2= newVec2(a.x * b, a.y * b)
proc `/`* (a: Vec2, b: float32): Vec2= newVec2(a.x / b, a.y / b)

proc `+=`* (a: Vec2, b: Vec2)= a.x += b.x; a.y += b.y
proc `-=`* (a: Vec2, b: Vec2)= a.x -= b.x; a.y -= b.y
proc `*=`* (a: Vec2, b: Vec2)= a.x *= b.x; a.y *= b.y
proc `/=`* (a: Vec2, b: Vec2)= a.x /= b.x; a.y /= b.y
proc `+=`* (a: Vec2, b: float32)= a.x += b; a.y += b
proc `-=`* (a: Vec2, b: float32)= a.x -= b; a.y -= b
proc `*=`* (a: Vec2, b: float32)= a.x *= b; a.y *= b
proc `/=`* (a: Vec2, b: float32)= a.x /= b; a.y /= b

proc `-`* (v: Vec2): Vec2 = v * -1
proc `==`* (a: Vec2, b: Vec2): bool=
    return a.x == b.x and a.y == b.y

proc move* (a: Vec2, by: Vec2)=
    a.x += by.x; a.y += by.y

proc length* (a: Vec2): float32=
    sqrt((a.x * a.x) + (a.y * a.y))

proc normalize* (v: Vec2): Vec2 =
    let len = v.length()
    if len > 0: return newVec2(v.x / len, v.y / len)
    else: return newVec2(0, 0)

proc dot* (a: Vec2, b: Vec2): float32=
    return (a.x * b.x) + (a.y * b.y)

proc cross* (a: Vec2, b: Vec2): float32 = a.x * b.y - a.y * b.x

proc angleBetween* (a: Vec2, b: Vec2): float32=
    return arccos(dot(a, b) / (a.length() * b.length()))

proc rotate* (a: Vec2, rad: float32)=
    let ca = cos(rad)
    let sa = sin(rad)
    a.x = ca * a.x - sa * a.y
    a.y = sa * a.x + ca * a.y

proc newMat4* (): Mat4=
    Mat4(
        a: Mat4Arr(
            m00: 0, m10: 0, m20: 0, m30: 0,
            m01: 0, m11: 0, m21: 0, m31: 0,
            m02: 0, m12: 0, m22: 0, m32: 0,
            m03: 0, m13: 0, m23: 0, m33: 0
        )
    )

proc newMat4* (
    m00, m10, m20, m30,
    m01, m11, m21, m31,
    m02, m12, m22, m32,
    m03, m13, m23, m33: float32
): Mat4=
    Mat4(
        a: Mat4Arr(
            m00: m00, m10: m10, m20: m20, m30: m30,
            m01: m01, m11: m11, m21: m21, m31: m31,
            m02: m02, m12: m12, m22: m22, m32: m32,
            m03: m03, m13: m13, m23: m23, m33: m33
        )
    )

proc identity* (): Mat4=
    newMat4(
        1'f32, 0'f32, 0'f32, 0'f32,
        0'f32, 1'f32, 0'f32, 0'f32,
        0'f32, 0'f32, 1'f32, 0'f32,
        0'f32, 0'f32, 0'f32, 1'f32
    )

proc translation* (x: float32, y: float32, z: float32): Mat4=
    newMat4(
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1
    )

proc translation* (off: Vec3): Mat4=
    translation(off.x, off.y, off.z)

proc translation* (off: Vec2): Mat4=
    translation(off.x, off.y, 0.0)

proc scale* (x: float32, y: float32, z: float32): Mat4=
    newMat4(
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
    )

proc scale* (scale: Vec3): Mat4= scale(scale.x, scale.y, scale.z)

proc rotX* (rad: float32): Mat4=
    let s = sin(rad); let c = cos(rad)
    newMat4(
        1, 0, 0, 0,
        0, c, -s, 0,
        0, s, c, 0,
        0, 0, 0, 1
    )

proc rotY* (rad: float32): Mat4=
    let s = sin(rad); let c = cos(rad)
    newMat4(
        c, 0, s, 0,
        0, 1, 0, 0,
        -s, 0, c, 0,
        0, 0, 0, 1
    )

proc rotZ* (rad: float32): Mat4=
    let s = sin(rad); let c = cos(rad)
    newMat4(
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )

proc transpose* (m: Mat4): Mat4=
    newMat4(
        m.a.m00, m.a.m01, m.a.m02, m.a.m03,
        m.a.m10, m.a.m11, m.a.m12, m.a.m13,
        m.a.m20, m.a.m21, m.a.m22, m.a.m23,
        m.a.m30, m.a.m31, m.a.m32, m.a.m33
    )

proc ortho* (ll: float32, r: float32, b: float32, t: float32, n: float32, f: float32): Mat4=
    var
        tx = -(r + ll) / (r - ll)
        ty = -(t + b) / (t - b)
        tz = -(f + n) / (f - n)
    newMat4(
        2 / (r - ll), 0, 0, tx,
        0, 2 / (t - b), 0, ty,
        0, 0, 2 / (f - n), tz,
        0, 0, 0, 1
    )

proc perspective* (fov: float32, ar: float32, nd: float32, fd: float32): Mat4=
    let fov_in_rad = fov * DEGTORAD
    let f = 1.0 / tan(fov_in_rad / 2.0)
    newMat4(
        f / ar, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (fd + nd) / (nd - fd), (2 * fd*nd) / (nd - fd),
        0, 0, -1, 0
    )

proc lookAt* (fr: Vec3, to: Vec3, up: Vec3): Mat4=
    let z = (to - fr).normalize() * -1
    let x = cross(up, z).normalize()
    let y = cross(z, x)
    newMat4(
        x.x, x.y, x.z, -dot(fr, x),
        y.x, y.y, y.z, -dot(fr, y),
        z.x, z.y, z.z, -dot(fr, z),
        0,   0,   0,    1
    )

proc mul* (a: Mat4, b: Mat4): Mat4=
    for i in 0..<4:
        for j in 0..<4:
            var sum = 0.0
            for k in 0..<4:
                sum += a.m[j + k * 4] * b.m[k + i * 4]
            result.m[j + i * 4] = sum

proc transform* (pos: Vec3, rot: Vec3, scale: Vec3): Mat4=
    result = identity()
    # result = nMul(result, nTranslation(-pos))
    result = mul(result, rotX(rot.x))
    result = mul(result, rotY(rot.y))
    result = mul(result, rotZ(rot.z))
    result = mul(result, translation(pos * 2))
    result = mul(result, scale(scale))

proc transform* (pos: Vec2, rot: float, scale: Vec2): Mat4=
    result = identity()
    result = mul(result, translation(-pos))
    result = mul(result, rotZ(rot))
    result = mul(result, translation(pos * 2))
    result = mul(result, scale(scale.x, scale.y, 0))

# Mat3 Functions
proc newMat3* (): Mat3=
    Mat3(
        a: Mat3Arr(
            m00: 0, m10: 0, m20: 0,
            m01: 0, m11: 0, m21: 0,
            m02: 0, m12: 0, m22: 0,
        )
    )

proc newMat3* (
    m00, m10, m20,
    m01, m11, m21,
    m02, m12, m22: float32
): Mat3=
    Mat3(
        a: Mat3Arr(
            m00: m00, m10: m10, m20: m20,
            m01: m01, m11: m11, m21: m21,
            m02: m02, m12: m12, m22: m22,
        )
    )

proc identityMat3* (): Mat3=
    newMat3(
        1'f32, 0'f32, 0'f32,
        0'f32, 1'f32, 0'f32,
        0'f32, 0'f32, 1'f32
    )

proc translationMat3* (x: float32, y: float32, z: float32): Mat3=
    newMat3(
        1, 0, x,
        0, 1, y,
        0, 0, z,
    )

proc translationMat3* (off: Vec3): Mat3=
    translationMat3(off.x, off.y, off.z)

proc scaleMat3* (x: float32, y: float32, z: float32): Mat3=
    newMat3(
        x, 0, 0,
        0, y, 0,
        0, 0, z
    )

proc scaleMat3* (scale: Vec3): Mat3= scaleMat3(scale.x, scale.y, scale.z)

proc rotXMat3* (rad: float32): Mat3=
    let s = sin(rad); let c = cos(rad)
    newMat3(
        1, 0, 0,
        0, c, -s,
        0, s, c,
    )

proc rotYMat3* (rad: float32): Mat3=
    let s = sin(rad); let c = cos(rad)
    newMat3(
        c, 0, s,
        0, 1, 0,
        -s, 0, c,
    )

proc rotZMat3* (rad: float32): Mat3=
    let s = sin(rad); let c = cos(rad)
    newMat3(
        c, -s, 0,
        s, c, 0,
        0, 0, 1,
    )

proc transposeMat3* (m: Mat3): Mat3=
    newMat3(
        m.a.m00, m.a.m01, m.a.m02,
        m.a.m10, m.a.m11, m.a.m12,
        m.a.m20, m.a.m21, m.a.m22
    )

proc newMat2* (m00, m10, m01, m11: float): Mat2=
    Mat2(
        a: Mat2Arr(m00: m00, m10: m10,
                 m01: m01, m11: m11)
    )

proc translation* (x, y: float): Mat2=
    result = newMat2(
        1, x,
        0, y
    )

proc scale* (x, y: float): Mat2=
    newMat2(
        x, 0,
        0, y
    )

proc rot* (rot: float): Mat2=
    let c = cos(rot)
    let s = sin(rot)
    newMat2(
        c, -s,
        s, c
    )

proc mul* (a: Mat2, b: Mat2): Mat2=
    let A = a.a.m00; let B = a.a.m10
    let C = a.a.m01; let D = a.a.m11

    let E = b.a.m00; let F = b.a.m10
    let G = b.a.m01; let H = b.a.m11

    return newMat2(
      A * E + B * G, A * F + B * H,
      C * E + D * G, C * G + D * H
    )

# USEFUL MATH FUNCTIONS
proc lerp* (a, b, t: float): float=
    return a + (b - a) * t

proc lerpPercent* (a, b, t:float): float=
    return (1 - t) * a + t * b

proc lerp* (a, b: Vec2, t: float): Vec2=
    result.x = lerp(a.x, b.x, t)
    result.y = lerp(a.y, b.y, t)

proc lerpPercent* (a, b: Vec2, t:float): Vec2=
    result.x = lerpPercent(a.x, b.x, t)
    result.y = lerpPercent(a.y, b.y, t)

proc lerp* (a, b: Vec3, t: float): Vec3=
    result.x = lerp(a.x, b.x, t)
    result.y = lerp(a.y, b.y, t)
    result.z = lerp(a.z, b.z, t)

proc lerpPercent* (a, b: Vec3, t:float): Vec3=
    result.x = lerpPercent(a.x, b.x, t)
    result.y = lerpPercent(a.y, b.y, t)
    result.z = lerpPercent(a.z, b.z, t)

proc `$`* (m: Mat4): string =
    result = "Mat4{\n"
    result &= $m.a.m00 &  " " & $m.a.m10 & " " & $m.a.m20 & " " & $m.a.m30 & "\n"
    result &= $m.a.m01 &  " " & $m.a.m11 & " " & $m.a.m21 & " " & $m.a.m31 & "\n"
    result &= $m.a.m02 &  " " & $m.a.m12 & " " & $m.a.m22 & " " & $m.a.m32 & "\n"
    result &= $m.a.m03 &  " " & $m.a.m13 & " " & $m.a.m23 & " " & $m.a.m33 & "\n}"

proc `$`* (v: Vec3): string =
    result = "Vec3{ " & $v.x & " " & $v.y & " " & $v.z & " }\n"

proc `$`* (v: Vec2): string =
    result = "Vec2{ " & $v.x & " " & $v.y & " }\n"

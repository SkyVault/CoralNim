import
    math

type
    V3* = ref object
        x* , y* , z* : float32

    V2* = ref object
        x*, y*: float32

    M4Arr = object
        m00*, m10*, m20*, m30*: float32
        m01*, m11*, m21*, m31*: float32
        m02*, m12*, m22*, m32*: float32
        m03*, m13*, m23*, m33*: float32

    M4* = object {.union.}
        m* : array[16, float32]
        a* : M4Arr

    M3Arr = object
        m00*, m10*, m20*: float32
        m01*, m11*, m21*: float32
        m02*, m12*, m22*: float32
    M3* = object {.union.}
        m* : array[9, float32]
        a* : M3Arr

const PI*       = 3.14159265359
const DEGTORAD* = PI / 180.0
const RADTODEG* = 180.0 / PI

proc newV3* (x: float = 0, y: float = 0, z: float = 0): V3=
    V3(x: x, y: y, z: z)

proc V3Up*     (): V3 = newV3(0, 1, 0)
proc V3Right*  (): V3 = newV3(1, 0, 0)
proc V3Left*   (): V3 = newV3(-1, 0, 0)
proc V3One*    (): V3 = newV3(1, 1, 1)

proc `+`* (a: V3, b: V3): V3= newV3(a.x + b.x, a.y + b.y, a.z + b.z)
proc `-`* (a: V3, b: V3): V3= newV3(a.x - b.x, a.y - b.y, a.z - b.z)
proc `*`* (a: V3, b: V3): V3= newV3(a.x * b.x, a.y * b.y, a.z * b.z)
proc `/`* (a: V3, b: V3): V3= newV3(a.x / b.x, a.y / b.y, a.z / b.z)
proc `+`* (a: V3, b: float32): V3= newV3(a.x + b, a.y + b, a.z + b)
proc `-`* (a: V3, b: float32): V3= newV3(a.x - b, a.y - b, a.z - b)
proc `*`* (a: V3, b: float32): V3= newV3(a.x * b, a.y * b, a.z * b)
proc `/`* (a: V3, b: float32): V3= newV3(a.x / b, a.y / b, a.z / b)

proc `+=`* (a: V3, b: V3)= a.x += b.x; a.y += b.y; a.z += b.z
proc `-=`* (a: V3, b: V3)= a.x -= b.x; a.y -= b.y; a.z -= b.z
proc `*=`* (a: V3, b: V3)= a.x *= b.x; a.y *= b.y; a.z *= b.z
proc `/=`* (a: V3, b: V3)= a.x /= b.x; a.y /= b.y; a.z /= b.z
proc `+=`* (a: V3, b: float32)= a.x += b; a.y += b; a.z += b
proc `-=`* (a: V3, b: float32)= a.x -= b; a.y -= b; a.z -= b
proc `*=`* (a: V3, b: float32)= a.x *= b; a.y *= b; a.z *= b
proc `/=`* (a: V3, b: float32)= a.x /= b; a.y /= b; a.z /= b
proc `-`* (v: V3): V3 = v * -1

proc `==`* (a: V3, b: V3): bool=
    return a.x == b.x and a.y == b.y and a.z == b.z

proc move* (a: V3, by: V3)=
    a.x += by.x; a.y += by.y; a.z += by.z;

proc length* (a: V3): float32=
    sqrt((a.x * a.x) + (a.y * a.y) + (a.z * a.z))

proc normalize* (v: V3): V3 =
    let len = v.length()
    if len > 0: return newV3(v.x / len, v.y / len, v.z / len)
    else: return newV3(0, 0, 0)

proc dot* (a: V3, b: V3): float32=
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z)

proc cross* (a: V3, b: V3): V3 =
    newV3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )

proc angleBetween* (a: V3, b: V3): float32=
    return arccos(dot(a, b) / (a.length() * b.length()))

# v2
proc newV2* (x: float = 0, y: float = 0): V2=
    V2(x: x, y: y)

proc newV2* [T](x: T= 0, y: T= 0): V2=
    V2(x: (float32)x, y: (float32)y)

proc toV3*     (v: V2): V3 = newV3(v.x, v.y, 0)
proc V2Up*     (): V2 = newV2(0, 1)
proc V2Right*  (): V2 = newV2(1, 0)
proc V2Left*   (): V2 = newV2(-1, 0)
proc V2One*    (): V2 = newV2(1, 1)

proc `+`* (a: V2, b: V2): V2= newV2(a.x + b.x, a.y + b.y)
proc `-`* (a: V2, b: V2): V2= newV2(a.x - b.x, a.y - b.y)
proc `*`* (a: V2, b: V2): V2= newV2(a.x * b.x, a.y * b.y)
proc `/`* (a: V2, b: V2): V2= newV2(a.x / b.x, a.y / b.y)
proc `+`* (a: V2, b: float32): V2= newV2(a.x + b, a.y + b)
proc `-`* (a: V2, b: float32): V2= newV2(a.x - b, a.y - b)
proc `*`* (a: V2, b: float32): V2= newV2(a.x * b, a.y * b)
proc `/`* (a: V2, b: float32): V2= newV2(a.x / b, a.y / b)

proc `+=`* (a: V2, b: V2)= a.x += b.x; a.y += b.y
proc `-=`* (a: V2, b: V2)= a.x -= b.x; a.y -= b.y
proc `*=`* (a: V2, b: V2)= a.x *= b.x; a.y *= b.y
proc `/=`* (a: V2, b: V2)= a.x /= b.x; a.y /= b.y
proc `+=`* (a: V2, b: float32)= a.x += b; a.y += b
proc `-=`* (a: V2, b: float32)= a.x -= b; a.y -= b
proc `*=`* (a: V2, b: float32)= a.x *= b; a.y *= b
proc `/=`* (a: V2, b: float32)= a.x /= b; a.y /= b

proc `-`* (v: V2): V2 = v * -1
proc `==`* (a: V2, b: V2): bool=
    return a.x == b.x and a.y == b.y

proc nMove* (a: V2, by: V2)=
    a.x += by.x; a.y += by.y

proc length* (a: V2): float32=
    sqrt((a.x * a.x) + (a.y * a.y))

proc normalize* (v: V2): V2 =
    let len = v.length()
    if len > 0: return newV2(v.x / len, v.y / len)
    else: return newV2(0, 0)

proc dot* (a: V2, b: V2): float32=
    return (a.x * b.x) + (a.y * b.y)

proc cross* (a: V2, b: V2): float32 = a.x * b.y - a.y * b.x

proc angleBetween* (a: V2, b: V2): float32=
    return arccos(dot(a, b) / (a.length() * b.length()))

proc rotate* (a: V2, rad: float32)=
    let ca = cos(rad)
    let sa = sin(rad)
    a.x = ca * a.x - sa * a.y
    a.y = sa * a.x + ca * a.y

proc newM4* (): M4=
    M4(
        a: M4Arr(
            m00: 0, m10: 0, m20: 0, m30: 0,
            m01: 0, m11: 0, m21: 0, m31: 0,
            m02: 0, m12: 0, m22: 0, m32: 0,
            m03: 0, m13: 0, m23: 0, m33: 0
        )
    )

proc newM4* (
    m00, m10, m20, m30,
    m01, m11, m21, m31,
    m02, m12, m22, m32,
    m03, m13, m23, m33: float32
): M4=
    M4(
        a: M4Arr(
            m00: m00, m10: m10, m20: m20, m30: m30,
            m01: m01, m11: m11, m21: m21, m31: m31,
            m02: m02, m12: m12, m22: m22, m32: m32,
            m03: m03, m13: m13, m23: m23, m33: m33
        )
    )

proc identity* (): M4=
    newM4(
        1'f32, 0'f32, 0'f32, 0'f32,
        0'f32, 1'f32, 0'f32, 0'f32,
        0'f32, 0'f32, 1'f32, 0'f32,
        0'f32, 0'f32, 0'f32, 1'f32
    )

proc translation* (x: float32, y: float32, z: float32): M4=
    newM4(
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1
    )

proc translation* (off: V3): M4=
    translation(off.x, off.y, off.z)

proc scale* (x: float32, y: float32, z: float32): M4=
    newM4(
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
    )

proc scale* (scale: V3): M4= scale(scale.x, scale.y, scale.z)

proc rotX* (rad: float32): M4=
    let s = sin(rad); let c = cos(rad)
    newM4(
        1, 0, 0, 0,
        0, c, -s, 0,
        0, s, c, 0,
        0, 0, 0, 1
    )

proc rotY* (rad: float32): M4=
    let s = sin(rad); let c = cos(rad)
    newM4(
        c, 0, s, 0,
        0, 1, 0, 0,
        -s, 0, c, 0,
        0, 0, 0, 1
    )

proc rotZ* (rad: float32): M4=
    let s = sin(rad); let c = cos(rad)
    newM4(
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )

proc transpose* (m: M4): M4=
    newM4(
        m.a.m00, m.a.m01, m.a.m02, m.a.m03,
        m.a.m10, m.a.m11, m.a.m12, m.a.m13,
        m.a.m20, m.a.m21, m.a.m22, m.a.m23,
        m.a.m30, m.a.m31, m.a.m32, m.a.m33
    )

proc ortho* (ll: float32, r: float32, b: float32, t: float32, n: float32, f: float32): M4=
    var
        tx = -(r + ll) / (r - ll)
        ty = -(t + b) / (t - b)
        tz = -(f + n) / (f - n)
    newM4(
        2 / (r - ll), 0, 0, tx,
        0, 2 / (t - b), 0, ty,
        0, 0, 2 / (f - n), tz,
        0, 0, 0, 1
    )

proc perspective* (fov: float32, ar: float32, nd: float32, fd: float32): M4=
    let fov_in_rad = fov * DEGTORAD
    let f = 1.0 / tan(fov_in_rad / 2.0)
    newM4(
        f / ar, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (fd + nd) / (nd - fd), (2 * fd*nd) / (nd - fd),
        0, 0, -1, 0
    )

proc lookAt* (fr: V3, to: V3, up: V3): M4=
    let z = (to - fr).normalize() * -1
    let x = cross(up, z).normalize()
    let y = cross(z, x)
    newM4(
        x.x, x.y, x.z, -dot(fr, x),
        y.x, y.y, y.z, -dot(fr, y),
        z.x, z.y, z.z, -dot(fr, z),
        0,   0,   0,    1
    )

proc mul* (a: M4, b: M4): M4=
    for i in 0..<4:
        for j in 0..<4:
            var sum = 0.0
            for k in 0..<4:
                sum += a.m[j + k * 4] * b.m[k + i * 4]
            result.m[j + i * 4] = sum

proc transform* (pos: V3, rot: V3, scale: V3): M4=
    result = identity()
    # result = nMul(result, nTranslation(-pos))
    result = mul(result, rotX(rot.x))
    result = mul(result, rotY(rot.y))
    result = mul(result, rotZ(rot.z))
    result = mul(result, translation(pos * 2))
    result = mul(result, scale(scale))

# M3 Functions
proc newM3* (): M3=
    M3(
        a: M3Arr(
            m00: 0, m10: 0, m20: 0,
            m01: 0, m11: 0, m21: 0,
            m02: 0, m12: 0, m22: 0,
        )
    )

proc newM3* (
    m00, m10, m20,
    m01, m11, m21,
    m02, m12, m22: float32
): M3=
    M3(
        a: M3Arr(
            m00: m00, m10: m10, m20: m20,
            m01: m01, m11: m11, m21: m21,
            m02: m02, m12: m12, m22: m22,
        )
    )

proc identityM3* (): M3=
    newM3(
        1'f32, 0'f32, 0'f32,
        0'f32, 1'f32, 0'f32,
        0'f32, 0'f32, 1'f32
    )

proc translationM3* (x: float32, y: float32, z: float32): M3=
    newM3(
        1, 0, x,
        0, 1, y,
        0, 0, z,
    )

proc translationM3* (off: V3): M3=
    translationM3(off.x, off.y, off.z)

proc scaleM3* (x: float32, y: float32, z: float32): M3=
    newM3(
        x, 0, 0,
        0, y, 0,
        0, 0, z
    )

proc scaleM3* (scale: V3): M3= scaleM3(scale.x, scale.y, scale.z)

proc rotXM3* (rad: float32): M3=
    let s = sin(rad); let c = cos(rad)
    newM3(
        1, 0, 0,
        0, c, -s,
        0, s, c,
    )

proc rotYM3* (rad: float32): M3=
    let s = sin(rad); let c = cos(rad)
    newM3(
        c, 0, s,
        0, 1, 0,
        -s, 0, c,
    )

proc rotZM3* (rad: float32): M3=
    let s = sin(rad); let c = cos(rad)
    newM3(
        c, -s, 0,
        s, c, 0,
        0, 0, 1,
    )

proc transposeM3* (m: M3): M3=
    newM3(
        m.a.m00, m.a.m01, m.a.m02,
        m.a.m10, m.a.m11, m.a.m12,
        m.a.m20, m.a.m21, m.a.m22
    )

# USEFUL MATH FUNCTIONS
proc lerp* (a, b, t: float): float=
    return a + (b - a) * t

proc lerpPercent* (a, b, t:float): float=
    return (1 - t) * a + t * b

proc lerp* (a, b: V2, t: float): V2=
    result.x = lerp(a.x, b.x, t)
    result.y = lerp(a.y, b.y, t)

proc lerpPercent* (a, b: V2, t:float): V2=
    result.x = lerpPercent(a.x, b.x, t)
    result.y = lerpPercent(a.y, b.y, t)

proc lerp* (a, b: V3, t: float): V3=
    result.x = lerp(a.x, b.x, t)
    result.y = lerp(a.y, b.y, t)
    result.z = lerp(a.z, b.z, t)

proc lerpPercent* (a, b: V3, t:float): V3=
    result.x = lerpPercent(a.x, b.x, t)
    result.y = lerpPercent(a.y, b.y, t)
    result.z = lerpPercent(a.z, b.z, t)

proc `$`* (m: M4): string =
    result = "M4{\n"
    result &= $m.a.m00 &  " " & $m.a.m10 & " " & $m.a.m20 & " " & $m.a.m30 & "\n"
    result &= $m.a.m01 &  " " & $m.a.m11 & " " & $m.a.m21 & " " & $m.a.m31 & "\n"
    result &= $m.a.m02 &  " " & $m.a.m12 & " " & $m.a.m22 & " " & $m.a.m32 & "\n"
    result &= $m.a.m03 &  " " & $m.a.m13 & " " & $m.a.m23 & " " & $m.a.m33 & "\n}"

proc `$`* (v: V3): string =
    result = "V3{ " & $v.x & " " & $v.y & " " & $v.z & " }\n"

proc `$`* (v: V2): string =
    result = "V2{ " & $v.x & " " & $v.y & " }\n"


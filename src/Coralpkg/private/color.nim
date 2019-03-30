import random, strutils

type
  Color* = object
    r*, g*, b*, a*: float

## Color stuff
proc newColor* (r, g, b, a=1.0): auto {.noSideEffect.}=
  result = Color(r: r, g: g, b: b, a: a)

proc colorFromHex* (hex: string): Color=
  var
    r = 0.0'f32
    g = 0.0'f32
    b = 0.0'f32
    a = 1.0'f32

  var nhex = ""
  if len(hex) > 1:
    if hex[0] == '#':
      nhex = hex[1..<len(hex)]
    else:
      nhex = hex
  else:
    echo "colorFromHex::Warning:: invalid color string: ", hex
    return newColor(r, g, b, a)

  case len(nhex):
  of 6:
    r = (float32(parseHexInt(nhex[0..1])) / 255.0)
    g = (float32(parseHexInt(nhex[2..3])) / 255.0)
    b = (float32(parseHexInt(nhex[4..5])) / 255.0)
  of 8:
    r = (float32(parseHexInt(nhex[0..1])) / 255.0)
    g = (float32(parseHexInt(nhex[2..3])) / 255.0)
    b = (float32(parseHexInt(nhex[4..5])) / 255.0)
    a = (float32(parseHexInt(nhex[6..7])) / 255.0)
  else:
    echo "hexColorToFloatColor::Error:: invalid color string: ", hex
    return newColor(r, g, b, a)

  return newColor(r, g, b, a)

template Red*                  ():untyped =newColor(1, 0, 0)
template Green*                ():untyped =newColor(0, 1, 0)
template Blue*                 ():untyped =newColor(0, 0, 1)
template White*                ():untyped =newColor(1, 1, 1)
template Black*                ():untyped =newColor(0, 0, 0)
template DarkGray*             ():untyped =newColor(0.2, 0.2, 0.2)
template LightGray*            ():untyped =newColor(0.8, 0.8, 0.8)
template Gray*                 ():untyped =newColor(0.5, 0.5, 0.5)
template Transperent*          ():untyped =newColor(1, 1, 1, 0)
template TransperentBlack*     ():untyped =newColor(0, 0, 0, 0)

#proc randomColor* ():Color=
#  newColor(random.random(1.0), random.random(1.0), random.random(1.0), 1.0)

template P8_Black*      ():untyped = newColor(0, 0, 0, 1)
template P8_DarkBlue*   ():untyped = newColor(29.0 / 255.0, 43.0 / 255.0, 83.0 / 255.0)
template P8_DarkPurple* ():untyped = newColor(126.0 / 255.0, 37.0 / 255.0, 83.0 / 255.0)
template P8_DarkGreen*  ():untyped = newColor(0.0, 135.0 / 255.0, 81.0 / 255.0)
template P8_Brown*      ():untyped = newColor(171.0 / 255.0, 82.0 / 255.0, 54.0 / 255.0)
template P8_DarkGray*   ():untyped = newColor(95.0 / 255.0, 87.0 / 255.0, 79.0 / 255.0)
template P8_LightGray*  ():untyped = newColor(194.0 / 255.0, 195.0 / 255.0, 199.0 / 255.0)
template P8_White*      ():untyped = newColor(1.0, 241.0 / 255.0, 232.0 / 255.0)
template P8_Red*        ():untyped = newColor(1.0, 0.0, 77.0 / 255.0)
template P8_Orange*     ():untyped = newColor(1.0, 163.0 / 255.0, 0.0)
template P8_Yellow*     ():untyped = newColor(1.0, 236.0 / 255.0, 39.0 / 255.0)
template P8_Green*      ():untyped = newColor(0.0, 228.0 / 255.0, 54.0 / 255.0)
template P8_Blue*       ():untyped = newColor(41.0 / 255.0, 173.0 / 255.0, 1.0)
template P8_Indigo*     ():untyped = newColor(131.0 / 255.0, 118.0 / 255.0, 156.0 / 255.0)
template P8_Pink*       ():untyped = newColor(1.0, 119.0 / 255.0, 168.0 / 255.0)
template P8_Peach*      ():untyped = newColor(1.0, 204.0 / 255.0, 170.0 / 255.0)

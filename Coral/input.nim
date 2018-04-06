# import
#     glfw

type
    CoralControlerNumber* {.pure.} = enum
        One = 1,
        Two,
        Three,
        Four

# #[
# GLFW_GAMEPAD_BUTTON_A   0
# GLFW_GAMEPAD_BUTTON_B   1
# GLFW_GAMEPAD_BUTTON_X   2
# GLFW_GAMEPAD_BUTTON_Y   3
# GLFW_GAMEPAD_BUTTON_LEFT_BUMPER   4
# GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER   5
# GLFW_GAMEPAD_BUTTON_BACK   6
# GLFW_GAMEPAD_BUTTON_START   7
# GLFW_GAMEPAD_BUTTON_GUIDE   8
# GLFW_GAMEPAD_BUTTON_LEFT_THUMB   9
# GLFW_GAMEPAD_BUTTON_RIGHT_THUMB   10
# GLFW_GAMEPAD_BUTTON_DPAD_UP   11
# GLFW_GAMEPAD_BUTTON_DPAD_RIGHT   12
# GLFW_GAMEPAD_BUTTON_DPAD_DOWN   13
# GLFW_GAMEPAD_BUTTON_DPAD_LEFT   14
# GLFW_GAMEPAD_BUTTON_LAST   GLFW_GAMEPAD_BUTTON_DPAD_LEFT
# GLFW_GAMEPAD_BUTTON_CROSS   GLFW_GAMEPAD_BUTTON_A
# GLFW_GAMEPAD_BUTTON_CIRCLE   GLFW_GAMEPAD_BUTTON_B
# GLFW_GAMEPAD_BUTTON_SQUARE   GLFW_GAMEPAD_BUTTON_X
# GLFW_GAMEPAD_BUTTON_TRIANGLE   GLFW_GAMEPAD_BUTTON_Y
# ]#

# type
#     # CoralButton* {.pure.}=enum
#     #     A = GLFW_GAMEPAD_BUTTON_A

#     CoralKey* {.pure.}= enum
#         Unknown = glfw.keyUnknown
#         Space = glfw.keySpace
#         Apostrophe = glfw.keyApostrophe
#         Comma = glfw.keyComma
#         Minus = glfw.keyMinus
#         Period = glfw.keyPeriod
#         Slash = glfw.keySlash
#         Num0 = glfw.key0
#         Num1 = glfw.key1
#         Num2 = glfw.key2
#         Num3 = glfw.key3
#         Num4 = glfw.key4
#         Num5 = glfw.key5
#         Num6 = glfw.key6
#         Num7 = glfw.key7
#         Num8 = glfw.key8
#         Num9 = glfw.key9
#         Semicolon  = glfw.keySemicolon
#         Equal = glfw.keyEqual
#         A = glfw.keyA
#         B = glfw.keyB
#         C = glfw.keyC
#         D = glfw.keyD
#         E = glfw.keyE
#         F = glfw.keyF
#         G = glfw.keyG
#         H = glfw.keyH
#         I = glfw.keyI
#         J = glfw.keyJ
#         K = glfw.keyK
#         L = glfw.keyL
#         M = glfw.keyM
#         N = glfw.keyN
#         O = glfw.keyO
#         P = glfw.keyP
#         Q = glfw.keyQ
#         R = glfw.keyR
#         S = glfw.keyS
#         T = glfw.keyT
#         U = glfw.keyU
#         V = glfw.keyV
#         W = glfw.keyW
#         X = glfw.keyX
#         Y = glfw.keyY
#         Z = glfw.keyZ
#         LeftBracket = glfw.keyLeftBracket
#         Backslash = glfw.keyBackslash
#         RightBracket = glfw.keyRightBracket
#         GraveAccent = glfw.keyGraveAccent
#         World1 = glfw.keyWorld1
#         World2 = glfw.keyWorld2
#         Escape = glfw.keyEscape
#         Enter = glfw.keyEnter
#         Tab = glfw.keyTab
#         Backspace = glfw.keyBackspace
#         Insert = glfw.keyInsert
#         Delete = glfw.keyDelete
#         Right = glfw.keyRight
#         Left = glfw.keyLeft
#         Down = glfw.keyDown
#         Up = glfw.keyUp
#         PageUp = glfw.keyPageUp
#         PageDown = glfw.keyPageDown
#         Home = glfw.keyHome
#         End = glfw.keyEnd
#         CapsLock = glfw.keyCapsLock
#         ScrollLock = glfw.keyScrollLock
#         NumLock = glfw.keyNumLock
#         PrintScreen = glfw.keyPrintScreen
#         Pause = glfw.keyPause
#         Func1 = glfw.keyF1
#         Func2 = glfw.keyF2
#         Func3 = glfw.keyF3
#         Func4 = glfw.keyF4
#         Func5 = glfw.keyF5
#         Func6 = glfw.keyF6
#         Func7 = glfw.keyF7
#         Func8 = glfw.keyF8
#         Func9 = glfw.keyF9
#         Func10 = glfw.keyF10
#         Func11 = glfw.keyF11
#         Func12 = glfw.keyF12
#         Func13 = glfw.keyF13
#         Func14 = glfw.keyF14
#         Func15 = glfw.keyF15
#         Func16 = glfw.keyF16
#         Func17 = glfw.keyF17
#         Func18 = glfw.keyF18
#         Func19 = glfw.keyF19
#         Func20 = glfw.keyF20
#         Func21 = glfw.keyF21
#         Func22 = glfw.keyF22
#         Func23 = glfw.keyF23
#         Func24 = glfw.keyF24
#         Func25 = glfw.keyF25
#         Kp0 = glfw.keyKp0
#         Kp1 = glfw.keyKp1
#         Kp2 = glfw.keyKp2
#         Kp3 = glfw.keyKp3
#         Kp4 = glfw.keyKp4
#         Kp5 = glfw.keyKp5
#         Kp6 = glfw.keyKp6
#         Kp7 = glfw.keyKp7
#         Kp8 = glfw.keyKp8
#         Kp9 = glfw.keyKp9
#         KpDecimal = glfw.keyKpDecimal
#         KpDivide = glfw.keyKpDivide
#         KpMultiply = glfw.keyKpMultiply
#         KpSubtract = glfw.keyKpSubtract
#         KpAdd = glfw.keyKpAdd
#         KpEnter = glfw.keyKpEnter
#         KpEqual = glfw.keyKpEqual
#         LeftShift = glfw.keyLeftShift
#         LeftControl = glfw.keyLeftControl
#         LeftAlt = glfw.keyLeftAlt
#         LeftSuper = glfw.keyLeftSuper
#         RightShift = glfw.keyRightShift
#         RightControl = glfw.keyRightControl
#         RightAlt = glfw.keyRightAlt
#         RightSuper = glfw.keyRightSuper
#         Menu = glfw.keyMenu
# #   KeyAction* {.size: int32.sizeof.} = enum
# #     kaUp = (0, "up")
# #     kaDown = (1, "down")
# #     kaRepeat = (2, "repeat")

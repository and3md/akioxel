import ../../matrices

type Orientation* {.pure.} = enum
  Horizontal
  Vertical

proc getValueForOrientation*(vec: Vector2, orientation: Orientation): float32 =
  case orientation
  of Orientation.Horizontal:
    return vec.x
  of Orientation.Vertical:
    return vec.y

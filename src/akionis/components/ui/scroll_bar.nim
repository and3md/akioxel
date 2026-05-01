import ../../base_types
import ../../colors
import ../../matrices
import math
from raylib as ray import nil

type
  Orientation* {.pure.} = enum
    Horizontal
    Vertical

  ScrollBar* = ref object of UiComponent
    orientation: Orientation
    maxValue: int32 = 100
    value: int32 = 0
    valueChanged: proc(newValue: int32)
    minThumbSize: int32 = 10

proc orientation*(comp: ScrollBar): Orientation =
  return comp.orientation

proc `orientation=`*(comp: ScrollBar, newOrientation: Orientation) =
  if comp.orientation == newOrientation:
    return
  comp.orientation = newOrientation
  comp.uiNeedsMinSizeUpdate


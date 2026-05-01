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
    onValueChanged: proc(newValue: int32)
    minThumbSize: int32 = 10

const scrollBarThicknes = 10

proc `orientation=`*(comp: ScrollBar, newOrientation: Orientation)

proc newScrollBar*(orientation: Orientation, name: string): ScrollBar =
  result = new(ScrollBar)
  initUiComponent(result, name)
  `orientation=`(result, orientation)

proc orientation*(comp: ScrollBar): Orientation =
  return comp.orientation

proc `orientation=`*(comp: ScrollBar, newOrientation: Orientation) =
  if comp.orientation == newOrientation:
    return
  comp.orientation = newOrientation
  case comp.orientation
  of Orientation.Horizontal:
    comp.widthFactor = 1
    comp.heightFactor = 0
  of Orientation.Vertical:
    comp.widthFactor = 0
    comp.heightFactor = 1
  comp.uiNeedsMinSizeUpdate

proc maxValue*(comp: ScrollBar): int32 =
  return comp.maxValue

proc `maxValue=`*(comp: ScrollBar, newMaxValue: int32) =
  if comp.maxValue == newMaxValue:
    return
  comp.maxValue = newMaxValue
  # TODO: should be value changed

proc value*(comp: ScrollBar): int32 =
  return comp.value

proc `value=`*(comp: ScrollBar, newValue: int32) =
  if comp.value == newValue:
    return
  comp.value = newValue
  if not comp.onValueChanged.isNil:
    comp.onValueChanged(newValue)


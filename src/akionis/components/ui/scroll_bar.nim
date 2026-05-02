import ../../base_types
import ../../colors
import ../../matrices
import math
import button_state
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
    backgroundColor: Color
    thumbColor: array[ButtonState, Color]
    thumbState: ButtonState

const scrollBarThicknes = 10

proc `orientation=`*(comp: ScrollBar, newOrientation: Orientation)

proc newScrollBar*(orientation: Orientation, name: string): ScrollBar =
  result = new(ScrollBar)
  initUiComponent(result, name)
  `orientation=`(result, orientation)
  result.backgroundColor = Black
  result.thumbColor[ButtonState.Up] = Blue
  result.thumbColor[ButtonState.Down] = Red
  result.thumbColor[ButtonState.Hover] = Yellow
  result.thumbState = ButtonState.Up

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

method calculateMinSize*(comp: ScrollBar) =
  var newMinSize =
    if comp.orientation == Orientation.Horizontal:
      Size(width: 30, height: scrollBarThicknes)
    else:
      Size(width: scrollBarThicknes, height: 30)
  applyMinMaxConstraint(newMinSize, comp.minConstraint, comp.maxConstraint)
  comp.minSize = newMinSize

method draw*(comp: ScrollBar, camera: Camera) =
  let data = comp.decomposedTransform(camera)
  ray.drawRectangle(
    ray.Rectangle(
      x: data.x,
      y: data.y,
      width: comp.size.width.float32 * data.scaleX,
      height: comp.size.height.float32 * data.scaleY,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    comp.backgroundColor,
  )

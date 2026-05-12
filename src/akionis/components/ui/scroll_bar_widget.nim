import ../../base_types
import ../../utils
import ../../colors
import ../../matrices
import math
import button_state
import orientation
from raylib as ray import nil

var lastGenNameNumber: uint32 = 0 

type
  ScrollBarWidget* = ref object of Widget
    orientation: Orientation
    maxValue: int32 = 100
    value: int32 = 0
    onValueChanged: proc(newValue: int32)
    minThumbSize: int32 = 10
    backgroundColor: Color
    thumbColor: array[ButtonState, Color]
    thumbState: ButtonState

const scrollBarThicknes = 15

proc `orientation=`*(comp: ScrollBarWidget, newOrientation: Orientation)

proc newScrollBarWidget*(parentNode: Node, orientation: Orientation, name: string = ""): ScrollBarWidget =
  result = new(ScrollBarWidget)
  initWidget(result, generateName(name, "ScrollBarWidget", lastGenNameNumber))
  # by default orientation is Horizontal so we should also set widthFactor to this orientation
  result.widthFactor = 1
  result.heightFactor = 0
  `orientation=`(result, orientation)
  result.backgroundColor = Black
  result.thumbColor[ButtonState.Up] = Blue
  result.thumbColor[ButtonState.Down] = Red
  result.thumbColor[ButtonState.Hover] = Yellow
  result.thumbState = ButtonState.Up
  if not parentNode.isNil:
    parentNode.addComponent(result)
  
proc newNodeWithScrollBarWidget*(parentNode: Node, orientation: Orientation, widgetName: string = ""): tuple[node: Node, widget: ScrollBarWidget] =
  ## Shortcut create widget with node and add it to parent node
  result.node = newNode()
  result.widget = newScrollBarWidget(result.node, orientation, widgetName)
  if not parentNode.isNil:
    parentNode.addChild(result.node)

proc orientation*(comp: ScrollBarWidget): Orientation =
  return comp.orientation

proc `orientation=`*(comp: ScrollBarWidget, newOrientation: Orientation) =
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

proc maxValue*(comp: ScrollBarWidget): int32 =
  return comp.maxValue

proc `maxValue=`*(comp: ScrollBarWidget, newMaxValue: int32) =
  if comp.maxValue == newMaxValue:
    return
  comp.maxValue = newMaxValue
  # TODO: should be value changed

proc value*(comp: ScrollBarWidget): int32 =
  return comp.value

proc `value=`*(comp: ScrollBarWidget, newValue: int32) =
  if comp.value == newValue:
    return
  comp.value = newValue
  if not comp.onValueChanged.isNil:
    comp.onValueChanged(newValue)

method calculateMinSize*(comp: ScrollBarWidget) =
  var newMinSize =
    if comp.orientation == Orientation.Horizontal:
      Size(width: 30, height: scrollBarThicknes)
    else:
      Size(width: scrollBarThicknes, height: 30)
  applyMinMaxConstraint(newMinSize, comp.minConstraint, comp.maxConstraint)
  comp.minSize = newMinSize

method draw*(comp: ScrollBarWidget, camera: Camera) =
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

  var pixelWidth =
    if comp.orientation == Orientation.Horizontal:
      comp.size.width.float32 * data.scaleX
    else:
      comp.size.height.float32 * data.scaleY

  #echo "Pixel width: ", pixelWidth

  var scaleForOrientation =
    if comp.orientation == Orientation.Horizontal: data.scaleX else: data.scaleY

  var pixelMaxValue = comp.maxValue.float32 * scaleForOrientation

  var pixelThumbMinSize = comp.minThumbSize.float32 * scaleForOrientation

  # pixelWidth < pixelMaxValue
  if pixelWidth > pixelMaxValue:
    # in this case we do not draw thumb
    return

  # how many pixelMaxValue fits the current size
  var pixelThumbSize = (pixelWidth / pixelMaxValue) * pixelWidth

  var pixelOffset =
    if comp.orientation == Orientation.Horizontal:
      data.x + (pixelWidth - pixelThumbSize) * (comp.value / comp.maxValue)
    else:
      data.y + (pixelWidth - pixelThumbSize) * (comp.value / comp.maxValue)

  ray.drawRectangle(
    ray.Rectangle(
      x:
        if comp.orientation == Orientation.Horizontal:
          pixelOffset
        else:
          data.x,
      y:
        if comp.orientation == Orientation.Horizontal:
          data.y
        else:
          pixelOffset,
      width: comp.size.width.float32 * data.scaleX,
      height: comp.size.height.float32 * data.scaleY,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    comp.thumbColor[comp.thumbState],
  )

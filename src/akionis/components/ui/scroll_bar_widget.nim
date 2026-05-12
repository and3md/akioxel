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
    thumbSize: int32 = 10
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

proc getThumbPixelRect(comp: ScrollBarWidget): Rect =
  ## Gets local pixel thumb rect
  let pixelWidth =
    if comp.orientation == Orientation.Horizontal:
      comp.size.width.float32
    else:
      comp.size.height.float32

  let pixelUnitValue =  pixelWidth / comp.maxValue.float32
  let pixelValue = pixelUnitValue * comp.value.float32
  let pixelThumbSize = pixelUnitValue * comp.thumbSize.float32

  result.x = if comp.orientation == Orientation.Horizontal:
    comp.offsetX + pixelValue
  else:
    comp.offsetX
  result.y = if comp.orientation == Orientation.Horizontal:
    comp.offsetY
  else:
    comp.offsetY + pixelValue
  result.width = if comp.orientation == Orientation.Horizontal:
    pixelThumbSize
  else:
    comp.size.width.float32
  result.height = if comp.orientation == Orientation.Horizontal:
    comp.size.height.float32
  else:
    pixelThumbSize
  

method draw*(comp: ScrollBarWidget, camera: Camera) =
  let data = comp.decomposedTransform(camera)

  let scaledWidth = comp.size.width.float32 * data.scaleX
  let scaledHeight = comp.size.height.float32 * data.scaleY

  # draw background
  ray.drawRectangle(
    ray.Rectangle(
      x: data.x,
      y: data.y,
      width: scaledWidth,
      height: scaledHeight,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    comp.backgroundColor,
  )

  let pixelWidth =
    if comp.orientation == Orientation.Horizontal:
      scaledWidth
    else:
      scaledHeight

  let pixelUnitValue =  pixelWidth / comp.maxValue.float32
  let pixelValue = pixelUnitValue * comp.value.float32
  let pixelThumbSize = pixelUnitValue * comp.thumbSize.float32

  ray.drawRectangle(
    ray.Rectangle(
      x:
        if comp.orientation == Orientation.Horizontal:
          data.x + pixelValue
        else:
          data.x,
      y:
        if comp.orientation == Orientation.Horizontal:
          data.y
        else:
          data.y + pixelValue,
      width: 
        if comp.orientation == Orientation.Horizontal:
          pixelThumbSize
        else:
          scaledWidth,
      height:
        if comp.orientation == Orientation.Horizontal:
          scaledHeight
        else:
          pixelThumbSize
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    comp.thumbColor[comp.thumbState],
  )



method update*(comp: ScrollBarWidget, deltaTime: float32) =
  ## Updates button state
  let parent = comp.parent
  if parent.isNil:
    return
  let camera = getGame().getFirstCameraFromMask(comp.cameras)
  if camera.isNil:
    return

  let mousePos = ray.getMousePosition()
  let worldMousePoint = screenPointToWorld(camera, mousePos)
  let localMousePoint = parent.worldPointToLocal(worldMousePoint)

  let pixelThumbRect = comp.getThumbPixelRect()

  if pointInsideRect(pixelThumbRect, localMousePoint):
     if ray.isMouseButtonDown(ray.MouseButton.Left):
       comp.thumbState = ButtonState.Down
     else:
       comp.thumbState = ButtonState.Hover
  else:
     comp.thumbState = ButtonState.Up

import ../../base_types
import ../../colors
import ../../matrices
import math
import ../../utils
from raylib as ray import nil

var lastGenNameNumber: uint32 = 0 

type RectangleWidget* = ref object of Widget
  color*: Color = Green

proc newRectangleWidget*(parentNode: Node, name: string = ""): RectangleWidget =
  result = new(RectangleWidget)
  initWidget(result, generateName(name, "RectangleWidget", lastGenNameNumber))
  if not parentNode.isNil:
    parentNode.addComponent(result)

proc newRectangleWidget*(parentNode: Node, width: int32, height: int32, name: string = ""): RectangleWidget =
  result = new(RectangleWidget)
  initWidget(result, generateName(name, "RectangleWidget", lastGenNameNumber))
  result.minConstraint = Size(width: width, height: height)
  result.maxConstraint = Size(width: width, height: height)

proc newNodeWithRectangleWidget*(parentNode: Node, widgetName: string = ""): tuple[node: Node, widget: RectangleWidget] =
  ## Shortcut create widget with node and add it to parent node
  result.node = newNode()
  result.widget = newRectangleWidget(result.node, widgetName)
  parentNode.addChild(result.node)

method draw*(rectView: RectangleWidget, camera: Camera) =
  let data = rectView.decomposedTransform(camera)
  ray.drawRectangle(
    ray.Rectangle(
      x: data.x,
      y: data.y,
      width: rectView.size.width.float32 * data.scaleX,
      height: rectView.size.height.float32 * data.scaleY,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    rectView.color,
  )

method calculateMinSize*(comp: RectangleWidget) =
  var newMinSize = Size(width: 100, height: 50)
  applyMinMaxConstraint(newMinSize, comp.minConstraint, comp.maxConstraint)
  comp.minSize = newMinSize


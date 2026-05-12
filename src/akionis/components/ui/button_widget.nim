import ../../base_types
import ../../colors
import ../../matrices
import ../../utils
import button_state
import math
from raylib as ray import nil

var lastGenNameNumber: uint32 = 0 

type
  ButtonWidget* = ref object of Widget
    state: ButtonState
    color*: array[ButtonState, Color]
    onClick*: proc(comp: ButtonWidget)
    onUpdate*: proc(comp: ButtonWidget, deltaTime: float32)

proc newButtonWidget*(parentNode: Node, name: string = ""): ButtonWidget =
  result = new(ButtonWidget)
  initWidget(result, generateName(name, "ButtonWidget", lastGenNameNumber))
  result.color[ButtonState.Up] = Blue
  result.color[ButtonState.Down] = Red
  result.color[ButtonState.Hover] = Yellow
  result.state = ButtonState.Up
  result.size = Size(width: 200, height: 40)
  parentNode.addComponent(result)

proc newNodeWithButtonWidget*(parentNode: Node, widgetName: string = ""): tuple[node: Node, widget: ButtonWidget] =
  ## Shortcut create widget with node and add it to parent node
  result.node = newNode()
  result.widget = newButtonWidget(result.node, widgetName)
  parentNode.addChild(result.node)

method draw*(button: ButtonWidget, camera: Camera) =
  let data = button.decomposedTransform(camera)
  ray.drawRectangle(
    ray.Rectangle(
      x: data.x,
      y: data.y,
      width: button.size.width.float32 * data.scaleX,
      height: button.size.height.float32 * data.scaleY,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    button.color[button.state],
  )

method calculateMinSize*(comp: ButtonWidget) =
  var newMinSize = Size(width: 50, height: 30)
  applyMinMaxConstraint(newMinSize, comp.minConstraint, comp.maxConstraint)
  comp.minSize = newMinSize

method update*(comp: ButtonWidget, deltaTime: float32) =
  ## Updates button state
  let parent = comp.parent
  if parent.isNil:
    return
  let camera = getGame().getFirstCameraFromMask(comp.cameras)
  if camera.isNil:
    return

  let mousePos = ray.getMousePosition()
  let worldMousePoint = screenPointToWorld(camera, mousePos)
  let boundingRect = worldBoundingBox(comp)

  if pointInsideRect(boundingRect, worldMousePoint):
    if ray.isMouseButtonDown(ray.MouseButton.Left):
      comp.state = ButtonState.Down
    else:
      comp.state = ButtonState.Hover
      # onClick support
      if ray.isMouseButtonReleased(ray.MouseButton.Left):
        if not comp.onClick.isNil:
          comp.onClick(comp)
  else:
    comp.state = ButtonState.Up

  # custom user update proc
  if not comp.onUpdate.isNil:
    comp.onUpdate(comp, deltaTime)

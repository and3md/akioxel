import ../../base_types
import ../../events
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

method processEvent*(comp: ButtonWidget, event: Event) =
  if event of MousePressEvent:
    comp.state = ButtonState.Down
  elif event of MouseReleaseEvent:
    if not comp.onClick.isNil:
      # code for future mouseEventTarget support
      # to dismiss click when user move cursor from control
      # let camera = getGame().getFirstActiveCameraFromMask(comp.cameras)
      # if camera.isNil:
      #   return
      # let worldMousePoint = screenPointToWorld(camera, mousePos)
      # let localMousePoint = parent.worldPointToLocal(worldMousePoint)
      # if pointInsideRect(Rect(x: comp.offsetX.float32, y: comp.offsetY.float32, width: comp.size.width.float32, height: comp.size.height.float32), localMousePoint):

      comp.onClick(comp)
    comp.state = ButtonState.Hover
  elif event of MouseExitEvent:
    comp.state = ButtonState.Up
  elif event of MouseEnterEvent:
    comp.state = ButtonState.Hover

method update*(comp: ButtonWidget, deltaTime: float32) =
  # custom user update proc
  if not comp.onUpdate.isNil:
    comp.onUpdate(comp, deltaTime)

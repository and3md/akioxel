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
    event.isHandled = true
  elif event of MouseReleaseEvent:
    # released outside the widget?
    let mouseEvent = MouseReleaseEvent(event)
    let parent = comp.parent
    if parent.isNil:
      return
    let camera = getGame().getFirstActiveCameraFromMask(comp.cameras)
    if camera.isNil:
      return
    let worldMousePoint = screenPointToWorld(camera, mouseEvent.screenMousePos)
    let localMousePoint = parent.worldPointToLocal(worldMousePoint)
    let insideWidget = pointInsideRect(comp.getWidgetArea, localMousePoint)

    if not comp.onClick.isNil:
      # Button after mouse press event intercepts mouse move and release events
      # but when user move mouse outside the control we don't want
      # run onClick
      if insideWidget:
        comp.onClick(comp)
    comp.state = if insideWidget: ButtonState.Hover else: ButtonState.Up
    event.isHandled = true
  elif event of MouseExitEvent:
    comp.state = ButtonState.Up
    event.isHandled = true
  elif event of MouseEnterEvent:
    comp.state = ButtonState.Hover
    event.isHandled = true

method update*(comp: ButtonWidget, deltaTime: float32) =
  # custom user update proc
  if not comp.onUpdate.isNil:
    comp.onUpdate(comp, deltaTime)

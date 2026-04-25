import ../../base_types
import ../../colors
import math
from raylib as ray import nil

type
  ButtonState {.pure.} = enum
    Up
    Down
    Hover

  ButtonComponent* = ref object of UiComponent
    state: ButtonState
    color*: array[ButtonState, Color]

proc newButton*(name: string): ButtonComponent =
  result = new(ButtonComponent)
  initUiComponent(result, name)
  result.color[ButtonState.Up] = Blue
  result.color[ButtonState.Down] = Red
  result.color[ButtonState.Hover] = Yellow
  result.state = ButtonState.Up
  result.size = Size(width: 200, height: 40)

method draw*(button: ButtonComponent, camera: Camera) =
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

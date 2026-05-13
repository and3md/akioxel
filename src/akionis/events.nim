import matrices
from raylib as ray import nil

type
  MouseButton = ray.MouseButton
  KeyboardKey = ray.KeyboardKey

  Event* = ref object of RootObj
    isHandled*: bool

  MouseEvent* = ref object of Event
    worldMousePos*: Vector2

  MousePressEvent* = ref object of MouseEvent
    pressedButton: MouseButton

  MouseReleaseEvent* = ref object of MouseEvent
    releasedButton: MouseButton

  MouseMoveEvent* = ref object of MouseEvent
    deltaMove: Vector2

proc newMousePressEvent(
    worldMousePos: Vector2, pressedButton: MouseButton
): MousePressEvent =
  result = new (MousePressEvent)
  result.worldMousePos = worldMousePos
  result.pressedButton = pressedButton

proc newMouseReleaseEvent(
    worldMousePos: Vector2, releasedButton: MouseButton
): MouseReleasedEvent =
  result = new (MouseReleasedEvent)
  result.worldMousePos = worldMousePos
  result.releasedButton = releasedButton

proc newMouseMoveEvent(
    worldMousePos, deltaMove: Vector2
): MouseReleasedEvent =
  result = new (MouseReleasedEvent)
  result.worldMousePos = worldMousePos
  result.deltaMove = deltaMove
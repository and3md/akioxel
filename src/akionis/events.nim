import matrices
from raylib as ray import nil

type
  MouseButton* = ray.MouseButton
  KeyboardKey* = ray.KeyboardKey

  Event* = ref object of RootObj
    isHandled*: bool

  MouseEvent* = ref object of Event
    screenMousePos*: Vector2
      ## We use screen mouse pos not world mouse pos because we don't want add iteration over cameras
      ## Let user decide what it should do 

  MousePressEvent* = ref object of MouseEvent
    pressedButton: MouseButton

  MouseReleaseEvent* = ref object of MouseEvent
    releasedButton: MouseButton

  MouseMoveEvent* = ref object of MouseEvent
    deltaMove: Vector2

proc newMousePressEvent*(
    screenMousePos: Vector2, pressedButton: MouseButton
): MousePressEvent =
  result = new (MousePressEvent)
  result.screenMousePos = screenMousePos
  result.pressedButton = pressedButton

proc newMouseReleaseEvent*(
    screenMousePos: Vector2, releasedButton: MouseButton
): MouseReleaseEvent =
  result = new (MouseReleaseEvent)
  result.screenMousePos = screenMousePos
  result.releasedButton = releasedButton

proc newMouseMoveEvent*(
    screenMousePos, deltaMove: Vector2
): MouseMoveEvent =
  result = new (MouseMoveEvent)
  result.screenMousePos = screenMousePos
  result.deltaMove = deltaMove
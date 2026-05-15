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

  MouseWheelMoveEvent* = ref object of MouseEvent
    deltaWheelMove: Vector2

  MouseEnterEvent* = ref object of MouseEvent
  MouseExitEvent* = ref object of MouseEvent

proc newMousePressEvent*(
    screenMousePos: Vector2, pressedButton: MouseButton
): MousePressEvent =
  result = new (MousePressEvent)
  result.screenMousePos = screenMousePos
  result.pressedButton = pressedButton

proc pressedButton*(event: MousePressEvent): MouseButton =
  return event.pressedButton

proc newMouseReleaseEvent*(
    screenMousePos: Vector2, releasedButton: MouseButton
): MouseReleaseEvent =
  result = new (MouseReleaseEvent)
  result.screenMousePos = screenMousePos
  result.releasedButton = releasedButton

proc releasedButton*(event: MouseReleaseEvent): MouseButton = 
  return event.releasedButton

proc newMouseMoveEvent*(
    screenMousePos, deltaMove: Vector2
): MouseMoveEvent =
  result = new (MouseMoveEvent)
  result.screenMousePos = screenMousePos
  result.deltaMove = deltaMove

proc newMouseWheelMoveEvent*(
    screenMousePos, deltaWheelMove: Vector2
): MouseWheelMoveEvent =
  result = new (MouseWheelMoveEvent)
  result.screenMousePos = screenMousePos
  result.deltaWheelMove = deltaWheelMove

proc newMouseEnterEvent*(
    screenMousePos: Vector2
): MouseEnterEvent =
  result = new (MouseEnterEvent)
  result.screenMousePos = screenMousePos

proc newMouseExitEvent*(
    screenMousePos: Vector2
): MouseExitEvent =
  result = new (MouseExitEvent)
  result.screenMousePos = screenMousePos

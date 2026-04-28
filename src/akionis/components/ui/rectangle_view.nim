import ../../base_types
import ../../colors
import ../../matrices
import math
from raylib as ray import nil


type
  RectangleView* = ref object of UiComponent
    color*: Color = Green

proc newRectangleView*(name:string): RectangleView =
  result = new(RectangleView)
  initUiComponent(result, name)

method draw*(rectView: RectangleView, camera: Camera) =
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

method calculateMinSize*(comp: RectangleView) =
  let newMinSize = Size(width: 100, height: 50)
  comp.minSize = newMinSize


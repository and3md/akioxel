import ../base_types
import ../colors
import vmath
from raylib as ray import nil

type
  Square* = ref object of RenderedComponent
    color*: Color
    size*: float32


proc newSquare*(size: float32, color: Color): Square =
  result = new(Square)
  result.size = size
  result.color = color

method draw*(square: Square, camera: Camera) =
  let data = square.decomposedTransform(camera)
  ray.drawRectangle(
    ray.Rectangle(
      x: data.x,
      y: data.y,
      width: square.size * data.scaleX,
      height: square.size * data.scaleY,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    square.color,
  )

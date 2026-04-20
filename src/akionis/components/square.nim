import ../base_types
import ../colors
import vmath
import ../matrices
from raylib as ray import nil

type Square* = ref object of RenderedComponent
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

method worldBoundingBox*(comp: Square): Rect =
  let parent = comp.parent
  if parent.isNil:
    raise newException(
      NoParentNode, "Can't calculate Square world bounding box without parent Node"
    )

  return globalRectFromVec3(
    parent.worldMatrix * translate(vec2(comp.offsetX, comp.offsetY)),
    vec3(0'f32, 0'f32, 1'f32),
    vec3(0'f32, comp.size, 1'f32),
    vec3(comp.size, comp.size, 1'f32),
    vec3(comp.size, 0'f32, 1'f32),
  )


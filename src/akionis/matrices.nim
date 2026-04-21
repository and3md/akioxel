import math
import vmath
from raylib as ray import nil

type
  Matrix3* = GMat3[float32]
  Vector3* = GVec3[float32]

  Rect* = ray.Rectangle

proc decomposeMatrix*(
    matrix: Matrix3
): tuple[x: float32, y: float32, angle: float32, scaleX: float32, scaleY: float32] =
  result.x = matrix[2, 0]
  result.y = matrix[2, 1]

  result.angle = math.arctan2(matrix[0, 1], matrix[0, 0])
  result.scaleX = vec2(matrix[0, 0], matrix[0, 1]).length
  result.scaleY = vec2(matrix[1, 0], matrix[1, 1]).length

proc globalRectFromVec3*(worldMatrix: Matrix3, p1, p2, p3, p4: Vector3): Rect =
  let world_p1 = worldMatrix * p1
  let world_p2 = worldMatrix * p2
  let world_p3 = worldMatrix * p3
  let world_p4 = worldMatrix * p4

  let min_x = min([world_p1.x, world_p2.x, world_p3.x, world_p4.x])
  let max_x = max([world_p1.x, world_p2.x, world_p3.x, world_p4.x])
  let min_y = min([world_p1.y, world_p2.y, world_p3.y, world_p4.y])
  let max_y = max([world_p1.y, world_p2.y, world_p3.y, world_p4.y])
  result.x = min_x
  result.y = min_y
  result.width = max_x - min_x
  result.height = max_y - min_y

const epsilon : float32 = 1e-7'f32

proc isZero*(value: float32): bool =
  return abs(value) < epsilon

proc rectMerge*(rect1, rect2: Rect):Rect =
  let r1x2 = rect1.x + rect1.width
  let r1y2 = rect1.y + rect1.height
  let r2x2 = rect2.x + rect2.width
  let r2y2 = rect2.y + rect2.height
  result.x = min(rect1.x, rect2.x)
  result.y = min(rect1.y, rect2.y)
  result.width = max(r1x2, r2x2) - result.x
  result.height = max(r1y2, r2y2) - result.y




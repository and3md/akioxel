import math
import vmath

type
  Matrix3* = GMat3[float32]    

proc decomposeMatrix(
    matrix: Matrix3
): tuple[x: float32, y: float32, angle: float32, scaleX: float32, scaleY: float32] =
  result.x = matrix[2, 0]
  result.y = matrix[2, 1]

  result.angle = math.arctan2(matrix[0, 1], matrix[0, 0])
  result.scaleX = vec2(matrix[0, 0], matrix[0, 1]).length
  result.scaleY = vec2(matrix[1, 0], matrix[1, 1]).length

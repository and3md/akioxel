import ../../base_types
import ../../colors
import ../../matrices
import math
import ../../textures
from raylib as ray import nil

type ImageUiComp* = ref object of UiComponent
  texture: SharedTexture
  tint*: Color

proc newImageUiComp*(name: string, texture: SharedTexture): ImageUiComp =
  result = new ImageUiComp
  initUiComponent(result, name)
  result.texture = texture
  result.tint = White

method calculateMinSize*(comp: ImageUiComp) =
  var newMinSize = Size(width: comp.texture.width, height: comp.texture.height)
  applyMinMaxConstraint(newMinSize, comp.minConstraint, comp.maxConstraint)
  comp.minSize = newMinSize

method draw*(comp: ImageUiComp, camera: Camera) =
  let data = comp.decomposedTransform(camera)
  drawSharedTexture(
    comp.texture,
    Rect(
      x: data.x,
      y: data.y,
      width: comp.size.width.float32 * data.scaleX,
      height: comp.size.height.float32 * data.scaleY,
    ),
    radToDeg(data.angle),
    comp.tint,
  )

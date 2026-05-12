import ../../base_types
import ../../utils
import ../../colors
import ../../matrices
import math
import ../../textures
from raylib as ray import nil

var lastGenNameNumber: uint32 = 0 

type ImageWidget* = ref object of Widget
  texture: SharedTexture
  tint*: Color

proc newImageWidget*(parentNode: Node, texture: SharedTexture, name: string = ""): ImageWidget =
  result = new ImageWidget
  initWidget(result, generateName(name, "ImageWidget", lastGenNameNumber))
  result.texture = texture
  result.tint = White
  if not parentNode.isNil:
    parentNode.addComponent(result)

proc newNodeWithImageWidget*(parentNode: Node, texture: SharedTexture, widgetName: string = ""): tuple[node:Node, widget: ImageWidget] =
  ## Shortcut create widget with node and add it to parent node
  result.node = newNode()
  result.widget = newImageWidget(result.node, texture, widgetName)
  if not parentNode.isNil:
    parentNode.addChild(result.node)

method calculateMinSize*(comp: ImageWidget) =
  var newMinSize = Size(width: comp.texture.width, height: comp.texture.height)
  applyMinMaxConstraint(newMinSize, comp.minConstraint, comp.maxConstraint)
  comp.minSize = newMinSize

method draw*(comp: ImageWidget, camera: Camera) =
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

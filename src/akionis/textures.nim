from raylib as ray import nil
import colors
import matrices
import utils

type
  Texture* = ray.Texture

  SharedTexture* = ref object of RootObj
    texture: Texture

proc newSharedTexture*(fileType: string, fileData: openArray[uint8]): SharedTexture =
  result = new(SharedTexture)
  var image = ray.loadImageFromMemory(fileType, fileData)
  result.texture = ray.loadTextureFromImage(image)

proc newSharedTexture*(fileType: string, fileData: string): SharedTexture =
  return newSharedTexture(fileType, fileData.toByteSeq)

proc width*(tex: SharedTexture): int32 =
  return tex.texture.width

proc height*(tex: SharedTexture): int32 =
  return tex.texture.height

proc drawSharedTexture*(tex: SharedTexture, x, y: float32, tint: Color = White) =
  ray.drawTexture(tex.texture, Vector2(x: x, y: y), tint)

proc drawSharedTexture*(
    tex: SharedTexture, x, y, rotation, scaleX, scaleY: float32, tint: Color = White
) =
  var srcRect = Rect(
    x: 0'f32,
    y: 0'f32,
    width: tex.texture.width.float32,
    height: tex.texture.height.float32,
  )
  var destRect = Rect(
    x: x,
    y: y,
    width: tex.texture.width.float32 * scaleX,
    height: tex.texture.width.float32 * scaleY,
  )
  ray.drawTexture(
    tex.texture, srcRect, destRect, Vector2(x: 0'f32, y: 0'f32), rotation, tint
  )

proc drawSharedTexture*(
    tex: SharedTexture, destRect: Rect, rotation: float32, tint: Color = White
) =
  var srcRect = Rect(
    x: 0'f32,
    y: 0'f32,
    width: tex.texture.width.float32,
    height: tex.texture.height.float32,
  )
  ray.drawTexture(
    tex.texture, srcRect, destRect, Vector2(x: 0'f32, y: 0'f32), rotation, tint
  )


from raylib as ray import nil
import colors
import matrices
import utils

type 
  Texture* = ray.Texture

  SharedTexture* = ref object of RootObj
    texture: Texture

proc newSharedTexture*(fileType: string; fileData: openArray[uint8]): SharedTexture = 
  result = new(SharedTexture)
  var image = ray.loadImageFromMemory(fileType,fileData)
  result.texture = ray.loadTextureFromImage(image)


proc newSharedTexture*(fileType: string; fileData: string): SharedTexture = 
  return newSharedTexture(fileType, fileData.toByteSeq)


proc width*(tex: SharedTexture): int32 = 
  return tex.texture.width

proc height*(tex: SharedTexture): int32 =
  return tex.texture.height

proc drawSharedTexture*(x, y: float32, tex: SharedTexture, tint: Color) =
  ray.drawTexture(tex.texture, Vector2(x: x, y:y), tint)


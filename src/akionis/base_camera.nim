# Camera related things

proc worldX*(cam:Camera):float32 =
  return cam.worldX

proc `worldX=`*(cam: Camera, newWorldX: float32) =
  cam.worldX = newWorldX
  cam.isDirty = true

proc worldY*(cam:Camera):float32 =
  return cam.worldY

proc `worldY=`*(cam: Camera, newWorldY: float32) =
  cam.worldY = newWorldY
  cam.isDirty = true

proc rotation*(cam:Camera):float32 =
  return cam.rotation

proc `rotation=`*(cam: Camera, newRotation: float32) =
  cam.rotation = newRotation
  cam.isDirty = true

proc scaleX*(cam:Camera):float32 =
  return cam.scaleX

proc `scaleX=`*(cam: Camera, newScale: float32) =
  cam.scaleX = newScale
  cam.isDirty = true

proc scaleY*(cam:Camera):float32 =
  return cam.scaleY

proc `scaleY=`*(cam: Camera, newScale: float32) =
  cam.scaleY = newScale
  cam.isDirty = true

proc `scale=`*(cam: Camera, newScale: float32) =
  cam.scaleX = newScale
  cam.scaleY = newScale
  cam.isDirty = true

proc newCamera*(worldX, worldY: float32): Camera =
  result = Camera(
    worldX: worldX,
    worldY: worldY,
    scaleX: 1.0,
    scaleY: 1.0,
    rotation: 0,
    isDirty: true,
    isActive: true,
  )
  result.isFullScreen = true
  result.texture = ray.loadRenderTexture(ray.getRenderWidth(), ray.getRenderHeight())

proc viewport*(cam: Camera): Rect =
  return cam.viewport

proc resizeCameraTexture(cam: Camera, newSize: Size) =
  echo "resize camera texture"
  if cam.texture.id != 0 and cam.texture.texture.width == newSize.width and
      cam.texture.texture.height == newSize.height:
    return
  cam.texture = ray.loadRenderTexture(newSize.width, newSize.height)

proc `viewport=`*(cam: Camera, newViewport: Rect) =
  echo "setting wievport"
  cam.viewport = newViewport
  cam.isFullScreen = false
  cam.resizeCameraTexture(
    Size(width: newViewport.width.int32, height: newViewport.height.int32)
  )

proc resetViewport*(cam: Camera) =
  cam.isFullScreen = true

proc updateCameraTransform(cam: Camera) =
  cam.matrix =
    scale(vec2(cam.scaleX, cam.scaleY)) * rotate(cam.rotation) *
     translate(vec2(-cam.worldX, -cam.worldY))
    
  cam.isDirty = false

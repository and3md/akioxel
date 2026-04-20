# Render component related things

method draw*(comp: RenderedComponent, camera: Camera) =
  ## Draw function to override
  discard

method addCamera*(comp: RenderedComponent, cam: Camera) =
  ## Add camera on 
  comp.cameras.incl(cam.id)

proc decomposedTransform*(comp: RenderedComponent, cam: Camera
): tuple[x: float32, y: float32, angle: float32, scaleX: float32, scaleY: float32] =
  ## Returns position, scale, and rotation taking into account camera, world matrix and component offset
  return decomposeMatrix(
    cam.matrix * comp.parent.worldMatrix * translate(vec2(comp.offsetX, comp.offsetY))
  )

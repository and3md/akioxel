# Render component related things

method draw*(comp: RenderedComponent, camera: Camera) =
  ## Draw function to override
  discard

method addCamera*(comp: RenderedComponent, cam: Camera) =
  ## Adds the id of a given camera to draw the component on it 
  comp.cameras.incl(cam.id)

method removeCamera*(comp: RenderedComponent, cam: Camera) =
  ## Removes the id of a given camera to stop drawing the component on it 
  comp.cameras.excl(cam.id)

proc decomposedTransform*(comp: RenderedComponent, cam: Camera
): tuple[x: float32, y: float32, angle: float32, scaleX: float32, scaleY: float32] =
  ## Returns position, scale, and rotation taking into account camera, world matrix and component offset
  return decomposeMatrix(
    cam.matrix * comp.parent.worldMatrix * translate(vec2(comp.offsetX, comp.offsetY))
  )

method worldBoundingBox*(comp: RenderedComponent): Rect =
  let parent = comp.parent
  if parent.isNil:
    raise newException(NoParentNode, "Can't calculate world bounding box without parent Node")
  let world_p1 = parent.worldMatrix * vec3(comp.offsetX, comp.offsetY, 1'f32)
  result.x = world_p1.x
  result.y = world_p1.y
  result.width = 0
  result.height = 0

proc drawBoundingBox*(comp: RenderedComponent, camera: Camera) =
  
  var rect = worldBoundingBox(comp)
  camera.rectInCamera(rect)
 
  ray.drawRectangleLines(rect, 1'f32, Yellow)
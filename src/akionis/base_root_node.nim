# RootNode related things included to base_types

proc updateAllTransforms(node: RootNode) =
  ## Updates world matricies with checking dirty flags
  ## 
  ## We need iterate all Nodes but not every matrix will be recalculated

  # we use false and identity matrix on first level
  # because this is checked in updateTransforms() proc
  node.updateTransforms(mat3(), false)

proc renderWithAllCameras(node: RootNode) =
  for cam in node.parentState.game.cameras:
    if cam.isActive:
      ray.beginTextureMode(cam.texture)
      node.doRender(cam)
      ray.endTextureMode()

  ray.beginTextureMode(node.parentState.game.screenTexture)
  # TODO: camera effects here
  for cam in node.parentState.game.cameras:
    if cam.isActive:
      #echo "rys"
      ray.drawTexture(
        cam.texture.texture,
        Rect(
          x: 0'f32,
          y: 0'f32,
          width: cam.texture.texture.width.float32,
          height: cam.texture.texture.height.float32,
        ),
        if cam.isFullScreen:
          Rect(
            x: 0'f32,
            y: 0'f32,
            width: cam.texture.texture.width.float32,
            height: cam.texture.texture.height.float32,
          )
        else:
          cam.viewport,
        ray.Vector2(x: 0'f32, y: 0'f32),
        0'f32,
        White,
      )
  ray.endTextureMode()

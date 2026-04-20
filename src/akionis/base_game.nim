# Game related functions

proc getGame*(): Game =
  if instance.isNil:
    raise newException(NoGameInstance, "No game instance")
  return instance


proc addFullScreenCamera*(game: Game, worldX, worldY: float32): Camera =
  ## Adds full screen camera that points to worldX, worldY in left top corrner
  var camera = newCamera(worldX, worldY)
  if game.lastCameraId.isNone:
    camera.id = Camera1
    game.lastCameraId = option(Camera1)
  else:
    if game.lastCameraId.get == high(CameraId):
      raise newException(ToManyCameras, "To many cameras")
    camera.id = succ(game.lastCameraId.get())
    game.lastCameraId = option(camera.id)
  game.cameras.add(camera)
  return camera

proc initGame*(
    windowWidth, windowHeight: int32, title: string, addDefaultCamera: bool = true
) =
  ## Initialises a new ``Game`` object.
  if instance.isNil:
    instance = Game(title: title)
    ray.setConfigFlags(ray.Flags[ray.ConfigFlags](ray.WindowResizable))
    ray.initWindow(windowWidth, windowHeight, title)
    instance.screenTexture =
      ray.loadRenderTexture(ray.getRenderWidth(), ray.getRenderHeight())
    if addDefaultCamera:
      discard instance.addFullScreenCamera(0.0, 0.0)
  else:
    raise newException(GameAlreadyCreated, "Game already created")

proc title*(game: Game): string =
  return game.title

proc `title=`*(game: Game, newTitle: string) =
  ray.setWindowTitle(newTitle)
  game.title = newTitle

proc getDefaultCamera*(game: Game): Camera =
  if game.cameras.len == 0:
    discard game.addFullScreenCamera(0.0, 0.0)

  return game.cameras[0]

proc openRootState*(game: Game, state: State) =
  if not game.state.isNil:
    game.state.doClose
  game.state = state
  state.start

proc updateGame*(game: Game, deltaTime: float32) =
  #echo ("update - start")
  if not game.state.isNil:
    game.state.doUpdate(deltaTime)

proc updateTransforms*(game: Game) =
  if not game.state.isNil:
    game.state.doUpdateTransform
  for cam in game.cameras:
    if cam.isActive and cam.isDirty:
      cam.updateCameraTransform

proc renderGameToTexture*(game: Game) =
  if not game.state.isNil:
    game.state.doRender

proc renderGame*(game: Game) =
  ## Renders game screen texture to screen
  # TODO: ascpect ratio, screen effects, etc here
  ray.drawTexture(
    game.screenTexture.texture,
    Rect(
      x: 0'f32,
      y: 0'f32,
      width: game.screenTexture.texture.width.float32,
      height: game.screenTexture.texture.height.float32,
    ),
    Rect(
      x: 0'f32,
      y: 0'f32,
      width: ray.getRenderWidth().float32,
      height: ray.getRenderHeight().float32,
    ),
    ray.Vector2(x: 0'f32, y: 0'f32),
    0'f32,
    White,
  )

proc wasResize*(game: Game): bool =
  return ray.isWindowResized()

proc doResize*(game: Game) =
  let w = ray.getRenderWidth()
  let h = ray.getRenderHeight()
  instance.screenTexture = ray.loadRenderTexture(w, h)
  for cam in game.cameras:
    if cam.isFullScreen:
      cam.resizeCameraTexture(Size(width: w, height: h))

iterator getCameras*(game: Game): Camera =
  for cam in game.cameras:
    yield cam


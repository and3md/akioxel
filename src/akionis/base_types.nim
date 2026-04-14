import std/options
import vmath
import matrices
import colors
from raylib as ray import nil

type
  Rectangle = ray.Rectangle

  Size* = object
    width: int32
    height: int32

  Game* = ref object of RootObj
    cameras: seq[Camera]
    lastCameraId: Option[CameraId]
    state: State
    title: string
    screenTexture: ray.RenderTexture2D

  CameraId* = enum
    Camera1
    Camera2
    Camera3
    Camera4
    Camera5
    Camera6
    Camera7
    Camera8

  CameraMask* = set[CameraId]

  Camera* = ref object of RootObj
    matrix: Matrix3
    id: CameraId
    viewport: Rectangle
    texture: ray.RenderTexture2D ## Should have viewport size
    worldX: float32 ## World pos x 
    worldY: float32 ## World pos x
    scaleX: float32 = 1.0
    scaleY: float32 = 1.0
    rotation: float32
    isActive*: bool = true
    isDirty: bool = true ## Should we recalculate camera matrix
    isFullScreen: bool = true ## When true don't use viewport

  State* = ref object of RootObj
    name*: string ## State name - no special meaning only for identification
    subState: State
    persistentUpdate*: bool = false ## Should be updated when there is a subState
    rootNode: RootNode ## The root node to which we add other nodes
    game: Game ## Reference to game

  Node* = ref object of RootObj
    children: seq[Node]
    parent: Node
    components: seq[Component]
    worldMatrix: Matrix3
    x: float32
    y: float32
    scaleX: float32 = 1.0
    scaleY: float32 = 1.0
    rotation: float32
    dirty: bool = true ## Should we recalculate camera matrix

  RootNode* = ref object of Node
    parentState: State

  Component* = ref object of RootObj
    name: string
    enabled: bool
    parent: Node

  RenderedComponent* = ref object of Component
    cameras: CameraMask
    offsetX*: float32
    offsetY*: float32

  Square* = ref object of RenderedComponent
    color*: Color
    size*: float32

  AkionisExcpetion* = object of CatchableError ## Base Akionis exception
  GameAlreadyCreated* = object of AkionisExcpetion
    ## Raised after second try game creation 

  NoGameInstance* = object of AkionisExcpetion
    ## Trying to get a game instance but was not created

  ToManyCameras* = object of AkionisExcpetion

var instance: Game

proc getGame*(): Game =
  if instance.isNil:
    raise newException(NoGameInstance, "No game instance")
  return instance

# ---------------   RenderComponent   ----------------------
method draw*(comp: RenderedComponent, camera: Camera) =
  discard

method addCamera*(comp: RenderedComponent, cam: Camera) =
  comp.cameras.incl(cam.id)

proc decomposedTransform*(comp: RenderedComponent, cam: Camera
): tuple[x: float32, y: float32, angle: float32, scaleX: float32, scaleY: float32] =
  ## Returns position, scale, and rotation taking into account camera, world matrix and component offset
  return decomposeMatrix(
    cam.matrix * comp.parent.worldMatrix * translate(vec2(comp.offsetX, comp.offsetY))
  )

# ---------------   Square   ----------------------

proc newSquare*(size: float32, color: Color): Square =
  result = new(Square)
  result.size = size
  result.color = color

method draw*(square: Square, camera: Camera) =
  let data = square.decomposedTransform(camera)
  ray.drawRectangle(
    ray.Rectangle(
      x: data.x,
      y: data.y,
      width: square.size * data.scaleX,
      height: square.size * data.scaleY,
    ),
    ray.Vector2(x: 0.0, y: 0.0),
    radToDeg(data.angle),
    square.color,
  )

# ---------------   Node   ----------------------

proc initNode*(self: Node, x, y, scaleX, scaleY, rot: float32) =
  self.x = x
  self.y = y
  self.scaleX = scaleX
  self.scaleY = scaleY
  self.rotation = rot

proc initNode*(self: Node, x, y: float32) =
  initNode(self, x, y, 1.0, 1.0, 0.0)

proc newNode*(x, y: float): Node =
  result = new(Node)
  initNode(result, x, y)

proc newNode*(x, y, scaleX, scaleY, rot: float32): Node =
  result = new(Node)
  initNode(result, x, y, scaleX, scaleY, rot)

proc x*(node: Node): float32 =
  return node.x

proc `x=`*(node: Node, newX: float32) =
  node.x = newX
  node.dirty = true

proc y*(node: Node): float32 =
  return node.y

proc `y=`*(node: Node, newY: float32) =
  node.y = newY
  node.dirty = true

proc scaleX*(node: Node): float32 =
  return node.scaleX

proc `scaleX=`*(node: Node, newScaleX: float32) =
  node.scaleX = newScaleX
  node.dirty = true

proc scaleY*(node: Node): float32 =
  return node.scaleY

proc `scaleY=`*(node: Node, newScaleY: float32) =
  node.scaleY = newScaleY
  node.dirty = true

proc rotation*(node: Node): float32 =
  return node.rotation

proc `rotation=`*(node: Node, newRotation: float) =
  node.rotation = newRotation
  node.dirty = true

proc addChild*(parentNode, newChild: Node) =
  parentNode.children.add(newChild)

proc addComponent*(node: Node, comp: Component) =
  node.components.add(comp)
  comp.parent = node

proc updateTransforms(node: Node, parentMatrix: Matrix3, isParentDirty: bool) =
  ## Update this Node worldMatrix only when this node is dirty or parentDirty
  if isParentDirty or node.dirty:
    node.worldMatrix =
      parentMatrix * translate(vec2(node.x, node.y)) * rotate(-node.rotation) *
      scale(vec2(node.scaleX, node.scaleY))

    for child in node.children:
      child.updateTransforms(node.worldMatrix, isParentDirty or node.dirty)
    node.dirty = false

proc render(node: Node, camera: Camera) =
  for comp in node.components:
    if comp of RenderedComponent:
      let renderComp = RenderedComponent(comp)
      if camera.id in renderComp.cameras:
        renderComp.draw(camera)

proc doRender(node: Node, camera: Camera) =
  node.render(camera)
  for child in node.children:
    child.doRender(camera)

# ---------------   RootNode   ----------------------

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
        Rectangle(
          x: 0'f32,
          y: 0'f32,
          width: cam.texture.texture.width.float32,
          height: cam.texture.texture.height.float32,
        ),
        if cam.isFullScreen:
          Rectangle(
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

# ---------------   Camera   ----------------------

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

proc viewport*(cam: Camera): Rectangle =
  return cam.viewport

proc resizeCameraTexture(cam: Camera, newSize: Size) =
  echo "resize camera texture"
  if cam.texture.id != 0 and cam.texture.texture.width == newSize.width and
      cam.texture.texture.height == newSize.height:
    return
  cam.texture = ray.loadRenderTexture(newSize.width, newSize.height)

proc `viewport=`*(cam: Camera, newViewport: Rectangle) =
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
    translate(vec2(-cam.worldX, -cam.worldY)) * rotate(cam.rotation) *
    scale(vec2(cam.scaleX, cam.scaleY))
  cam.isDirty = false

# ---------------   State   ----------------------

proc initState*(self: State, game: Game, name: string) =
  self.name = name
  self.rootNode = new(RootNode)
  self.rootNode.parentState = self
  self.game = game

method close*(state: State) =
  echo "Close state ", state.name

method update*(state: State, deltaTime: float32) =
  echo "Update in state ", state.name

method start*(state: State) =
  echo "Start state ", state.name

method stop*(state: State) =
  echo "Stop state ", state.name

proc doClose(state: State) =
  ## Takes care of recursive close of all states
  # Close child state first
  if not state.subState.isNil:
    state.subState.doClose
  state.close

proc doUpdate(state: State, deltaTime: float32) =
  ## Takes care of correct updating everything
  if state.persistentUpdate or state.subState.isNil:
    state.update(deltaTime)
  if not state.subState.isNil:
    state.subState.update(deltaTime)

proc closeSubState(parentState: State) =
  if not parentState.subState.isNil:
    parentState.subState.doClose

proc openSubState(parentState, subState: State) =
  ## Opens substate (with closing if other is open)
  if not parentState.subState.isNil:
    parentState.subState.doClose
  parentState.subState = subState
  subState.start

proc doRender(state: State) =
  if state.isNil:
    return
  state.rootNode.renderWithAllCameras()
  if not state.subState.isNil:
    doRender(state.subState)

proc doUpdateTransform(state: State) =
  if state.isNil:
    return
  if state.persistentUpdate or state.subState.isNil:
    state.rootNode.updateAllTransforms
  doUpdateTransform(state.subState)

proc rootNode*(state: State): RootNode =
  return state.rootNode

proc game*(state: State): Game =
  return state.game

# ---------------   Game   ----------------------

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
    Rectangle(
      x: 0'f32,
      y: 0'f32,
      width: game.screenTexture.texture.width.float32,
      height: game.screenTexture.texture.height.float32,
    ),
    Rectangle(
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

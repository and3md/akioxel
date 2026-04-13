import std/options
import vmath
import matrices
from raylib as ray import nil

type
  Color = ray.Color

  Game* = ref object of RootObj
    cameras: seq[Camera]
    lastCameraId: Option[CameraId]
    state: State
    title: string

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
    x: float32
    y: float32
    scaleX: float32 = 1.0
    scaleY: float32 = 1.0
    rotation: float32
    dirty: bool = true ## Should we recalculate camera matrix

  State* = ref object of RootObj
    name*: string ## State name - no special meaning only for identification
    subState: State
    persistentUpdate*: bool = false ## Should be updated when there is a subState
    rootNode: RootNode ## The root node to which we add other nodes

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

var instance: Game
const Red* = Color(r: 255, g: 0, b: 0, a: 255)

proc getGame*(): Game =
  if instance.isNil:
    raise newException(NoGameInstance, "No game instance")
  return instance

# ---------------   RenderComponent   ----------------------
method draw*(comp: RenderedComponent) =
  discard

# ---------------   Square   ----------------------

proc newSquare*(size: float32, color: Color): Square =
  result = new(Square)
  result.size = size
  result.color = color

method draw*(square: Square) =
  let data = decomposeMatrix(
    square.parent.worldMatrix * translate(vec2(square.offsetX, square.offsetY))
  )
  ray.drawRectangle(
    ray.Rectangle(x: data.x, y: data.y, width: square.size, height: square.size),
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
      parentMatrix * rotate(node.rotation) * scale(vec2(node.scaleX, node.scaleY)) *
      translate(vec2(node.x, node.y))
    for child in node.children:
      child.updateTransforms(node.worldMatrix, isParentDirty or node.dirty)
    node.dirty = false

proc render(node: Node) =
  for comp in node.components:
    if comp of RenderedComponent:
      let renderComp = RenderedComponent(comp)
      renderComp.draw

proc doRender(node: Node) =
  node.render
  for child in node.children:
    child.doRender

# ---------------   RootNode   ----------------------

proc updateAllTransforms(node: RootNode) =
  ## Updates world matricies with checking dirty flags
  ## 
  ## We need iterate all Nodes but not every matrix will be recalculated

  # we use false and identity matrix on first level
  # because this is checked in updateTransforms() proc
  node.updateTransforms(mat3(), false)

# ---------------   Camera   ----------------------

proc initCamera*(x, y, scaleX, scaleY, rotation: float32): Camera =
  return Camera(x: x, y: y, scaleX: scaleY, rotation: rotation, dirty: true)

# ---------------   State   ----------------------

proc initState*(self: State, name: string) =
  self.name = name
  self.rootNode = new(RootNode)

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
  state.rootNode.doRender()
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

# ---------------   Game   ----------------------

proc initGame*(windowWidth, windowHeight: int32, title: string) =
  ## Initialises a new ``Game`` object.
  if instance.isNil:
    instance = Game(title: title)
    ray.initWindow(windowWidth, windowHeight, title)
  else:
    raise newException(GameAlreadyCreated, "Game already created")

proc title*(game: Game): string =
  return game.title

proc `title=`*(game: Game, newTitle: string) =
  ray.setWindowTitle(newTitle)
  game.title = newTitle

proc addCamera*(game: Game, x, y, scaleX, scaleY, rotation: float32): Camera =
  game.cameras.add(initCamera(x, y, scaleX, scaleY, rotation))
  return game.cameras[-1]

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

proc renderGame*(game: Game) =
  if not game.state.isNil:
    game.state.doRender

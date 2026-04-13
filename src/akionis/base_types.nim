import std/options
import vmath
import matrices
from raylib as ray import nil

type
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
    scaleX: float32
    scaleY: float32
    rotation: float32
    dirty: bool ## Should we recalculate camera matrix

  State* = ref object of RootObj
    name*: string
    subState: State
    persistentUpdate*: bool = false ## Should be updated when there is a subState
    nodes: seq[Node] ## Nodes of this State

  Node* = ref object of RootObj
    children: seq[Node]
    parent: Node
    components: seq[Component]
    worldMatrix: Matrix3
    x: float32
    y: float32
    scaleX: float32
    scaleY: float32
    rotation: float32
    dirty: bool ## Should we recalculate camera matrix

  RootNode* = ref object of Node
    parentState: State

  Component* = ref object of RootObj
    name: string
    enabled: bool

  AkionisExcpetion* = object of CatchableError ## Base Akionis exception
  GameAlreadyCreated* = object of AkionisExcpetion
    ## Raised after second try game creation 

  NoGameInstance* = object of AkionisExcpetion
    ## Trying to get a game instance but was not created

var instance: Game

proc getGame*(): Game =
  if instance.isNil:
    raise newException(NoGameInstance, "No game instance")
  return instance

# ---------------   Camera   ----------------------
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

proc `scaleX`*(node: Node, newScaleX: float32) =
  node.scaleX = newScaleX
  node.dirty = true

proc scaleY*(node: Node): float32 =
  return node.scaleY

proc `scaleY`*(node: Node, newScaleY: float32) =
  node.scaleY = newScaleY
  node.dirty = true

proc rotation*(node: Node): float32 = 
  return node.rotation

proc rotation*(node: Node, newRotation: float) =
  node.rotation = newRotation
  node.dirty = true

proc updateTransforms(node: Node, parentMatrix: Matrix3, isParentDirty: bool) =
  ## Update this Node worldMatrix only when this node is dirty or parentDirty
  if isParentDirty or node.dirty:
    node.worldMatrix =
      parentMatrix * rotate(node.rotation) * scale(vec2(node.scaleX, node.scaleY)) *
      translate(vec2(node.x, node.y))
    for child in node.children:
      child.updateTransforms(node.worldMatrix, isParentDirty or node.dirty)
    node.dirty = false

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

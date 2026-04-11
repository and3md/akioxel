import std/options
import vmath
from raylib as ray import nil

type
  Matrix3* = GMat3[float32]

  Game* = ref object of RootObj
    cameras: seq[Camera]
    lastCameraId: Option[CameraId]
    state: State
    title: string

  CameraId* = enum 
    Camera1, Camera2, Camera3, Camera4, Camera5, Camera6, Camera7, Camera8

  CameraMask* = set[CameraId]

  Camera* = ref object of RootObj
    id: CameraId
    x: float32
    y: float32
    scaleX: float32
    scaleY: float32
    rotation: float32
    dirty: bool ## Should we recalculate camera matrix
    matrix: Matrix3

  State* = ref object of RootObj
    name*: string
    subState: State
    persistentUpdate*: bool = false ## Should be updated when there is a subState
    nodes: seq[Node] ## Nodes of this State

  Node* = ref object of RootObj
    state: State
    children: seq[Node]
    components: seq[Component]

  Component* = ref object of RootObj
    name: string
    enabled: bool

var instance: Game

proc getGame*(): Game =
  if instance.isNil:
    raise newException(ValueError, "No game instance")
  return instance

proc initGame*(windowWidth, windowHeight: int32, title: string) =
  ## Initialises a new ``Game`` object.
  if instance.isNil:
    instance = Game(title: title)
    ray.initWindow(windowWidth, windowHeight, title)
  else:
    raise newException(ValueError, "Game already created")

proc initCamera*(x, y, scaleX, scaleY, rotation: float32): Camera =
  return Camera(x: x, y: y, scaleX: scaleY, rotation: rotation, dirty: true)

proc title*(game: Game): string =
  return game.title

proc `title=`*(game: Game, newTitle: string) =
  ray.setWindowTitle(newTitle)
  game.title = newTitle

proc addCamera*(game: Game, x, y, scaleX, scaleY, rotation: float32): Camera =
  game.cameras.add(initCamera(x, y, scaleX, scaleY, rotation))
  return game.cameras[-1]

method close*(state:State) {.base.} = 
  echo "Close state ", state.name

method update*(state:State, deltaTime: float32) {.base.} =
  echo "Update in state ", state.name

method start*(state:State) {.base.} =
  echo "Start state ", state.name

method stop*(state:State) {.base.} =
  echo "Stop state ", state.name

proc doUpdate(state:State, deltaTime: float32) = 
  echo ("update - starta")
  if state.persistentUpdate or not state.subState.isNil:
    state.update(deltaTime)
  if not state.subState.isNil:
    state.subState.update(deltaTime)

proc closeSubState(parentState:State) =
  if not parentState.subState.isNil:
    parentState.subState.close

proc openSubState(parentState, subState:State) =
  if not parentState.subState.isNil:
    parentState.subState.close
  parentState.subState = subState
  subState.start

# ---------------   Game ----------------------

proc openRootState(game: Game, state:State) =

  if not game.state.isNil:
    game.state.close
  game.state = state
  state.start

proc updateGame*(game:Game, deltaTime: float32) = 
  #echo ("update - start")
  if not game.state.isNil:
    game.state.doUpdate(deltaTime)

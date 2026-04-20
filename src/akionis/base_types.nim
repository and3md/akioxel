import std/options
import vmath
import matrices
import colors
from raylib as ray import nil

type
  Rectangle* = ray.Rectangle

  Size* = object
    width*: int32
    height*: int32

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
    cameras: CameraMask = {Camera1}
    offsetX*: float32
    offsetY*: float32

  AkionisExcpetion* = object of CatchableError ## Base Akionis exception
  GameAlreadyCreated* = object of AkionisExcpetion
    ## Raised after second try game creation 

  NoGameInstance* = object of AkionisExcpetion
    ## Trying to get a game instance but was not created

  ToManyCameras* = object of AkionisExcpetion

var instance: Game

# Base type's procs and methods are included from their files

include base_camera

include base_render_component

include base_node
include base_root_node

include base_state

include base_game
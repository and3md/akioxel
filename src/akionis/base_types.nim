import std/options
import vmath
import matrices
import colors
from raylib as ray import nil

type
  Size* = object
    width*: int32
    height*: int32

  Game* = ref object of RootObj
    ## Engine main object, holding the cameras and the current state
    cameras: seq[Camera] ## Sequence of cameras
    lastCameraId: Option[CameraId] ## Last used camera id in cameras
    state: State ## State stack
    title: string ## Title on window caption
    screenTexture: ray.RenderTexture2D ## Texture used to draw anything

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
    matrix: Matrix3 ## View matrix
    invMatrix: Matrix3 ## Needed to calculate world pos from screen pos
    id: CameraId
    viewport: Rect
      ## The window space (rect) on which this camera draws (only when isFullScreen == false)
    visibleWorldRect: Rect ## World rect visible in the camera (used for culling)
    texture: ray.RenderTexture2D ## Texture on wich we reder, should have viewport size
    worldX: float32 ## World pos x 
    worldY: float32 ## World pos x
    scaleX: float32 = 1.0
    scaleY: float32 = 1.0
    rotation: float32
    isActive*: bool = true ## Should this camera render anything
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
    cachedWorldBoundingBox: Rect
    x: float32
    y: float32
    scaleX: float32 = 1.0
    scaleY: float32 = 1.0
    rotation: float32
    isDirty: bool = true ## Should we recalculate world matrix

  RootNode* = ref object of Node
    parentState: State
    hasUi: bool ## Does this hierarchy have ui elements?
    needUiSizeUpdate: bool ## Should Ui recalculate its size
    needUiLayoutUpdate: bool ## Should Ui update its layout

  Component* = ref object of RootObj
    name*: string
    parent: Node
    isExisting: bool

  RenderedComponent* = ref object of Component
    cameras: CameraMask = {Camera1}
    offsetX: float32
    offsetY: float32

  ScriptComponent* = ref object of Component ## Component that runs update method

  ClosureComponent* = ref object of Component ## Component that runs onUpdate callback
    onUpdate*: proc(self: ClosureComponent, deltaTime: float)

  UiComponent* = ref object of RenderedComponent ## Base component for all UI components
    calculatedMinSize*: Size ## Minimum size with paddings calculated using content size
    minSize: Size
      ## Allows you to set the minimum size with paddings 0,0 means no constraints
    maxSize: Size
      ## Allows you to set the maximim size with paddings 0,0 means no constraints
    widthFactor: int32
      ## width factor flag:
      ## 0 - do not expand (use min or min calculated),
      ## 1 - expands, 
      ## 2 - expands twice as strong as 1 etc.
    heightFactor: int32
      ## heiht factor flag:
      ## 0 - do not expand (use min or min calculated),
      ## 1 - expands, 
      ## 2 - expands twice as strong as 1 etc.
    size: Size
      ## current used size with padding, can be set when UiComponent is not in layout
    contentSize: Size ## size of content without paddings
    padding: UiPadding ## space between conntent and border
    isEnabled: bool ## is widget enabled
    wantTabFocus: bool ## do widget wants focus from tab key 
    tabIndex: Positive ## tab index in parent 

  UiPadding* = object
    left*: int32
    right*: int32
    top*: int32
    bottom*: int32

  AkionisExcpetion* = object of CatchableError ## Base Akionis exception
  GameAlreadyCreated* = object of AkionisExcpetion
    ## Raised after second try game creation 

  NoGameInstance* = object of AkionisExcpetion
    ## Trying to get a game instance but was not created

  ToManyCameras* = object of AkionisExcpetion

  NoParentNode* = object of AkionisExcpetion
    ## When you try use component function that need parent

  NoRootNode* = object of AkionisExcpetion ## When searching/getting RootNode failed

  NoSizeForUi* = object of AkionisExcpetion
    ## The top-level Ui node must have a maxSize set to calculate the size of the entire Ui.

var instance: Game

# Size -----------------------------------------------------

proc sizeEmpty*(size: Size): bool =
  ## At least one of width or height is 0
  return size.width == 0 or size.height == 0

proc sizeCompletelyEmpty*(size: Size): bool =
  ## Width and height is zero
  return size.width == 0 and size.height == 0

proc applyMinMaxSize*(size: var Size, minSize, maxSize: Size) =
  ## Applies constraints to size
  # min width
  if minSize.width != 0 and size.width < minSize.width:
    size.width = minSize.width
  # min height
  if minSize.height != 0 and size.height < minSize.height:
    size.height = minSize.height
  #max width
  if maxSize.width != 0 and size.width > maxSize.width:
    size.width = maxSize.width
  #max height
  if maxSize.height != 0 and size.height > maxSize.height:
    size.height = maxSize.height

# Camera ---------------------------------------------------

proc worldX*(cam: Camera): float32 =
  return cam.worldX

proc `worldX=`*(cam: Camera, newWorldX: float32) =
  cam.worldX = newWorldX
  cam.isDirty = true

proc worldY*(cam: Camera): float32 =
  return cam.worldY

proc `worldY=`*(cam: Camera, newWorldY: float32) =
  cam.worldY = newWorldY
  cam.isDirty = true

proc rotation*(cam: Camera): float32 =
  return cam.rotation

proc `rotation=`*(cam: Camera, newRotation: float32) =
  cam.rotation = newRotation
  cam.isDirty = true

proc scaleX*(cam: Camera): float32 =
  return cam.scaleX

proc `scaleX=`*(cam: Camera, newScale: float32) =
  cam.scaleX = newScale
  cam.isDirty = true

proc scaleY*(cam: Camera): float32 =
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
  if ray.isTextureValid(cam.texture.texture) and
      cam.texture.texture.width == newSize.width and
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

  cam.invMatrix = inverse(cam.matrix)

  let topLeftCorner =
    if cam.isFullScreen:
      cam.invMatrix * vec3(0'f32, 0'f32, 1'f32)
    else:
      cam.invMatrix * vec3(cam.viewport.x, cam.viewport.y, 1'f32)

  let bottomRightCorner =
    if cam.isFullScreen:
      cam.invMatrix *
        vec3(
          cam.texture.texture.width.float32, cam.texture.texture.height.float32, 1'f32
        )
    else:
      cam.invMatrix *
        vec3(
          cam.viewport.x + cam.viewport.width,
          cam.viewport.y + cam.viewport.height,
          1'f32,
        )

  # simple code like that - does not work with camera rotation
  # but is suitable for most cases so I add if here
  if cam.rotation.isZero:
    cam.visibleWorldRect.x = topLeftCorner.x
    cam.visibleWorldRect.y = topLeftCorner.y
    cam.visibleWorldRect.width = bottomRightCorner.x - topLeftCorner.x
    cam.visibleWorldRect.height = bottomRightCorner.y - topLeftCorner.y
  else:
    # in this case we need get x1,x2, y1, y2 andf find min and max
    # rect will be greater than screen/window but that the best case
    # so we use AABB not OBB what is slower
    let topRightCorner =
      if cam.isFullScreen:
        cam.invMatrix * vec3(cam.texture.texture.width.float32, 0'f32, 1'f32)
      else:
        cam.invMatrix * vec3(cam.viewport.x + cam.viewport.width, cam.viewport.y, 1'f32)
    let bottomLeftCorner =
      if cam.isFullScreen:
        cam.invMatrix * vec3(0'f32, cam.texture.texture.height.float32, 1'f32)
      else:
        cam.invMatrix * vec3(
          cam.viewport.x, cam.viewport.y + cam.viewport.height, 1'f32
        )
    cam.visibleWorldRect = boundingRectForPoints(
      Vector2(x: topLeftCorner.x, y: topLeftCorner.y),
      Vector2(x: topRightCorner.x, y: topRightCorner.y),
      Vector2(x: bottomLeftCorner.x, y: bottomLeftCorner.y),
      Vector2(x: bottomRightCorner.x, y: bottomRightCorner.y),
    )

  echo "Camera transform update:"
  echo "Screen size: ", ray.getRenderWidth(), ", ", ray.getRenderHeight()
  echo "Visible world in camera: ", cam.visibleWorldRect
  if cam.isFullScreen:
    echo "Viewport: 0, 0 ", cam.texture.texture.width, ", ", cam.texture.texture.height
  else:
    echo "Viewport: ",
      cam.viewport.x, ", ", cam.viewport.y, ", ", cam.viewport.width, ", ",
      cam.viewport.height

  # After update camera is no longer dirty
  cam.isDirty = false

proc screenPointToWorld*(cam: Camera, point: Vector2): Vector2 =
  ## Returns point in world cooridnate system
  let worldPoint = cam.invMatrix * vec3(point.x, point.y, 1'f32)
  result.x = worldPoint.x
  result.y = worldPoint.y

proc rectInCamera(cam: Camera, rect: var Rect): OrientedRect =
  ## Transforms rect for camera view, used by drawing bounding boxes
  let c1 = cam.matrix * vec3(rect.x, rect.y, 1'f32)
  let c2 = cam.matrix * vec3(rect.x + rect.width, rect.y, 1'f32)
  let c3 = cam.matrix * vec3(rect.x + rect.width, rect.y + rect.height, 1'f32)
  let c4 = cam.matrix * vec3(rect.x, rect.y + rect.height, 1'f32)
  result.corners[0].x = c1.x
  result.corners[0].y = c1.y
  result.corners[1].x = c2.x
  result.corners[1].y = c2.y
  result.corners[2].x = c3.x
  result.corners[2].y = c3.y
  result.corners[3].x = c4.x
  result.corners[3].y = c4.y

# Component ------------------------------------------------

proc initComponent*(comp: Component, name: string) =
  comp.isExisting = true
  comp.name = name

proc parent*(comp: Component): Node =
  return comp.parent

proc isExisting*(comp: Component): bool =
  return comp.isExisting

method `isExisting=`*(comp: Component, newValue: bool) =
  comp.isExisting = newValue

method componentAddedToRoot(comp: Component, root: RootNode) =
  ## Method runs when component is added to rootNode
  discard

# RenderedComponent ----------------------------------------

proc initRenderedComponent*(comp: RenderedComponent, name: string) =
  initComponent(comp, name)

method `isExisting=`*(comp: RenderedComponent, newValue: bool) =
  if comp.isExisting == newValue:
    return
  comp.isExisting = newValue
  if not comp.parent.isNil:
    comp.parent.isDirty = true

proc cameras*(comp: RenderedComponent): CameraMask =
  return comp.cameras

proc offsetX*(comp: RenderedComponent): float32 =
  return comp.offsetX

proc `offsetX=`*(comp: RenderedComponent, newValue: float32) =
  if not almostEqual(comp.offsetX, newValue):
    comp.offsetX = newValue
    if comp.isExisting and (not comp.parent.isNil):
      comp.parent.isDirty = true

proc offsetY*(comp: RenderedComponent): float32 =
  return comp.offsetY

proc `offsetY=`*(comp: RenderedComponent, newValue: float32) =
  if not almostEqual(comp.offsetY, newValue):
    comp.offsetY = newValue
    if comp.isExisting and (not comp.parent.isNil):
      comp.parent.isDirty = true

method draw*(comp: RenderedComponent, camera: Camera) =
  ## Draw function to override
  discard

method addCamera*(comp: RenderedComponent, cam: Camera) =
  ## Adds the id of a given camera to draw the component on it 
  comp.cameras.incl(cam.id)

method removeCamera*(comp: RenderedComponent, cam: Camera) =
  ## Removes the id of a given camera to stop drawing the component on it 
  comp.cameras.excl(cam.id)

proc decomposedTransform*(
    comp: RenderedComponent, cam: Camera
): tuple[x: float32, y: float32, angle: float32, scaleX: float32, scaleY: float32] =
  ## Returns position, scale, and rotation taking into account camera, world matrix and component offset
  return decomposeMatrix(
    cam.matrix * comp.parent.worldMatrix * translate(vec2(comp.offsetX, comp.offsetY))
  )

method worldBoundingBox*(comp: RenderedComponent): Rect =
  let parent = comp.parent
  if parent.isNil:
    raise newException(
      NoParentNode, "Can't calculate world bounding box without parent Node"
    )
  let world_p1 = parent.worldMatrix * vec3(comp.offsetX, comp.offsetY, 1'f32)
  result.x = world_p1.x
  result.y = world_p1.y
  result.width = 0
  result.height = 0

proc drawBoundingBox*(comp: RenderedComponent, camera: Camera) =
  var rect = worldBoundingBox(comp)
  let orect = camera.rectInCamera(rect)

  ray.drawLine(orect.corners[0], orect.corners[1], Yellow)
  ray.drawLine(orect.corners[1], orect.corners[2], Yellow)
  ray.drawLine(orect.corners[2], orect.corners[3], Yellow)
  ray.drawLine(orect.corners[3], orect.corners[0], Yellow)

# ScriptComponent ------------------------------------------

method update*(self: ScriptComponent, deltaTime: float32) =
  echo "Empty script"

# UiComponent ----------------------------------------------

proc initUiComponent*(comp: UiComponent, name: string) =
  initRenderedComponent(comp, name)

proc getRootNode*(node: Node): RootNode

proc uiNeedsSizeUpdate*(comp: UiComponent) = 
  let parent = comp.parent
  if not parent.isNil:
    let rootNode = getRootNode(parent)
    if not rootNode.isNil:
      rootNode.needUiSizeUpdate = true

proc size*(comp: UiComponent): Size =
  return comp.size

proc minSize*(comp: UiComponent): Size =
  return comp.minSize

proc maxSize*(comp: UiComponent): Size =
  return comp.maxSize

proc `maxSize=`*(comp: UiComponent, newMaxSize: Size) =
  if comp.maxSize == newMaxSize:
    return
  comp.maxSize = newMaxSize
  comp.uiNeedsSizeUpdate

proc heightFactor*(comp: UiComponent): int32 =
  return comp.heightFactor

proc `heightFactor=`*(comp: UiComponent, newHeightFactor: int32) =
  if comp.heightFactor == newHeightFactor:
    return
  comp.heightFactor = newHeightFactor
  comp.uiNeedsSizeUpdate

proc widthFactor*(comp: UiComponent): int32 =
  return comp.widthFactor

proc `widthFactor=`*(comp: UiComponent, newWidthFactor: int32) =
  if comp.widthFactor == newWidthFactor:
    return
  comp.widthFactor = newWidthFactor
  comp.uiNeedsSizeUpdate

proc padding*(comp: UIComponent): UiPadding =
  return comp.padding

proc `size=`*(comp: UiComponent, newSize: Size) =
  if comp.size == newSize:
    return
  comp.size = newSize
  if comp.isExisting and (not comp.parent.isNil):
    comp.parent.isDirty = true

method componentAddedToRoot(comp: UiComponent, root: RootNode) =
  root.needUiSizeUpdate = true
  root.hasUi = true

method draw*(comp: UiComponent, camera: Camera) =
  echo "draw ui component"

method calculateMinSize*(comp: UiComponent) =
  ## Method to calculate minimum size
  comp.calculatedMinSize = Size(width: 0, height: 0)

method updateSize*(comp: UiComponent, availableSize: Size) =
  ## Method to update size with children
  comp.calculateMinSize
  var newSize = comp.calculatedMinSize
  applyMinMaxSize(newSize, comp.minSize, comp.maxSize)
  if comp.size == newSize:
    return
  comp.size = newSize
  if not comp.parent.isNil:
    comp.parent.isDirty = true

method update*(comp: UiComponent, deltaTime: float32) =
  ## Widget code that need to be run every frame,
  ## Size calculation should be done in calculateMinSize and updateSize
  discard

method worldBoundingBox*(comp: UiComponent): Rect =
  let parent = comp.parent
  if parent.isNil:
    raise newException(
      NoParentNode, "Can't calculate Ui world bounding box without parent Node"
    )

  return globalRectFromVec3(
    parent.worldMatrix * translate(vec2(comp.offsetX, comp.offsetY)),
    vec3(0'f32, 0'f32, 1'f32),
    vec3(0'f32, comp.size.height.float32, 1'f32),
    vec3(comp.size.width.float32, comp.size.height.float32, 1'f32),
    vec3(comp.size.width.float32, 0'f32, 1'f32),
  )

# Node -----------------------------------------------------

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
  node.isDirty = true

proc y*(node: Node): float32 =
  return node.y

proc `y=`*(node: Node, newY: float32) =
  node.y = newY
  node.isDirty = true

proc scaleX*(node: Node): float32 =
  return node.scaleX

proc `scaleX=`*(node: Node, newScaleX: float32) =
  node.scaleX = newScaleX
  node.isDirty = true

proc scaleY*(node: Node): float32 =
  return node.scaleY

proc `scaleY=`*(node: Node, newScaleY: float32) =
  node.scaleY = newScaleY
  node.isDirty = true

proc rotation*(node: Node): float32 =
  return node.rotation

proc `rotation=`*(node: Node, newRotation: float) =
  node.rotation = newRotation
  node.isDirty = true

proc makeDirty*(node: Node) =
  node.isDirty = true

proc getRootNode*(node: Node): RootNode =
  ## Gets RootNode from any other node in hierarchy
  if node of RootNode:
    return RootNode(node)
  if node.parent.isNil:
    return nil
  if node.parent of RootNode:
    return RootNode(node.parent)
  else:
    return getRootNode(node.parent)

proc worldMatrix*(node: Node): Matrix3 =
  return node.worldMatrix

proc nodeAddedToRoot(node: Node, rootNode: RootNode) =
  echo "Node added to root"
  for child in node.children:
    child.nodeAddedToRoot(rootNode)

  for comp in node.components:
    comp.componentAddedToRoot(rootNode)

proc addChild*(parentNode, newChild: Node) =
  parentNode.children.add(newChild)
  let rootNode = parentNode.getRootNode
  if not rootNode.isNil:
    nodeAddedToRoot(newChild, rootNode)

proc addComponent*(node: Node, comp: Component) =
  node.components.add(comp)
  comp.parent = node
  if comp.isExisting and comp of RenderedComponent:
    node.isDirty = true
    let rootNode = node.getRootNode
    if not rootNode.isNil:
      comp.componentAddedToRoot(rootNode)

proc hasComponentOfType*[T](node: Node): bool =
  ## Checks, does node have component of type T
  for comp in node.components:
    if comp of T:
      return true
  return false

proc getFirstComponentOfType*[T](node: Node): T =
  ## Returns first component of type T from node
  for comp in node.components:
    if comp of T:
      return T(comp)
  return nil

iterator getChildren*(node: Node): Node =
  ## Node children iterator
  for n in node.children:
    yield n

iterator getChildrenWithFirstComponentOfType*[T](
    node: Node
): tuple[node: Node, comp: T] =
  ## Iterator that returns tuple with Node and first component of type T
  var comp: T
  for n in node.children:
    comp = getFirstComponentOfType[T](n)
    if not comp.isNil:
      yield (node: n, comp: comp)

iterator getChildrenWithUi*(node: Node): tuple[node: Node, comp: UiComponent] =
  ## Iterator that returns tuple with Node and first UiComponent from the Node
  for n in getChildrenWithFirstComponentOfType[UiComponent](node):
    yield n

method calculateWorldBoundingBox(node: Node): Rect =
  var wasFirst = false
  for comp in node.components:
    if not comp.isExisting:
      continue
    if comp of RenderedComponent:
      if wasFirst:
        result = rectMerge(result, RenderedComponent(comp).worldBoundingBox())
      else:
        result = RenderedComponent(comp).worldBoundingBox()
        wasFirst = true
  for child in node.children:
    if wasFirst:
      result = rectMerge(result, child.calculateWorldBoundingBox)
    else:
      result = child.calculateWorldBoundingBox
      wasFirst = true

proc worldBoundingBox*(node: Node): Rect =
  return node.cachedWorldBoundingBox

proc updateTransforms(node: Node, parentMatrix: Matrix3, isParentDirty: bool): bool =
  ## Update this Node worldMatrix only when this node is dirty or parentDirty
  ## Returns true when something changes
  if isParentDirty or node.isDirty:
    node.worldMatrix =
      parentMatrix * translate(vec2(node.x, node.y)) * rotate(-node.rotation) *
      scale(vec2(node.scaleX, node.scaleY))

  result = isParentDirty or node.isDirty
  for child in node.children:
    if child.updateTransforms(node.worldMatrix, isParentDirty or node.isDirty):
      result = true
  # When result is true we need update cached WorldBoundingBox
  if result:
    node.cachedWorldBoundingBox = node.calculateWorldBoundingBox
  node.isDirty = false

proc drawComponentsBoundingBoxes*(node: Node, camera: Camera) =
  for comp in node.components:
    if comp of RenderedComponent:
      RenderedComponent(comp).drawBoundingBox(camera)

proc drawComponentsAndChildrenBoundingBoxes*(node: Node, camera: Camera) =
  drawComponentsBoundingBoxes(node, camera)
  for child in node.children:
    child.drawComponentsBoundingBoxes(camera)

proc drawNodeBoundingBox*(node: Node, camera: Camera) =
  var nodeBoundingBox = node.worldBoundingBox
  let orientedBoundingBox = camera.rectInCamera(nodeBoundingBox)
  ray.drawLine(orientedBoundingBox.corners[0], orientedBoundingBox.corners[1], Magenta)
  ray.drawLine(orientedBoundingBox.corners[1], orientedBoundingBox.corners[2], Magenta)
  ray.drawLine(orientedBoundingBox.corners[2], orientedBoundingBox.corners[3], Magenta)
  ray.drawLine(orientedBoundingBox.corners[3], orientedBoundingBox.corners[0], Magenta)

proc drawNodeAndChildrenBoundingBoxes*(node: Node, camera: Camera) =
  drawNodeBoundingBox(node, camera)
  for child in node.children:
    drawNodeAndChildrenBoundingBoxes(child, camera)

proc render(node: Node, camera: Camera) =
  for comp in node.components:
    if not comp.isExisting:
      continue
    if comp of RenderedComponent:
      let renderComp = RenderedComponent(comp)
      if camera.id in renderComp.cameras:
        renderComp.draw(camera)
  when defined(drawComponentsBoundingBoxes):
    node.drawComponentsAndChildrenBoundingBoxes(camera)
  when defined(drawNodesBoundingBoxes):
    node.drawNodeBoundingBox(camera)

proc doRender(node: Node, camera: Camera) =
  # Simple brute force culling by checking bounding box and camera visibleWorldRect
  # Maybe it's worth add quadtree in the future
  if rectsOverlaps(camera.visibleWorldRect, node.worldBoundingBox):
    node.render(camera)
    for child in node.children:
      child.doRender(camera)

proc doUpdate(node: Node, deltaTime: float) =
  for comp in node.components:
    if not comp.isExisting:
      continue
    if comp of UiComponent:
      update(UiComponent(comp), deltaTime)
    if comp of ScriptComponent:
      update(ScriptComponent(comp), deltaTime)
    elif comp of ClosureComponent:
      let closureComp = ClosureComponent(comp)
      if not closureComp.onUpdate.isNil:
        closureComp.onUpdate(closureComp, deltaTime)
  for child in node.children:
    child.doUpdate(deltaTime)

# RootNode -------------------------------------------------

proc updateAllTransforms(node: RootNode) =
  ## Updates world matricies with checking dirty flags, and updates ui sizes when needed
  ## 
  ## We need iterate all Nodes but not every matrix will be recalculated

  # we use false and identity matrix on first level
  # because this is checked in updateTransforms() proc
  discard node.updateTransforms(mat3(), false)

  if node.needUiSizeUpdate:
    # currently ui nodes must start in child of root node
    # this is a design assumption
    for childWithUi in node.getChildrenWithUi:
      if sizeEmpty(childWithUi.comp.maxSize):
        raise newException(NoSizeForUi, "Top-level ui component must have max size")
      childWithUi.comp.updateSize(childWithUi.comp.maxSize)
    node.needUiSizeUpdate = false
    # TODO: is it necessary? Maybe do not update transform second time 
    # Currently only after needUiSizeUpdate 
    discard node.updateTransforms(mat3(), false)

proc renderWithAllCameras(node: RootNode) =
  for cam in node.parentState.game.cameras:
    if cam.isActive:
      ray.beginTextureMode(cam.texture)
      ray.clearBackground(Color(r: 0, g: 0, b: 0, a: 0))
      node.doRender(cam)
      ray.endTextureMode()

  ray.beginTextureMode(node.parentState.game.screenTexture)
  ray.clearBackground(Color(r: 0, g: 0, b: 0, a: 0))
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

# State ----------------------------------------------------

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
    state.rootNode.doUpdate(deltaTime)
  if not state.subState.isNil:
    state.subState.update(deltaTime)
    state.subState.rootNode.doUpdate(deltaTime)

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

# Game -----------------------------------------------------

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
    instance.lastCameraId = none(CameraId)
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
      cam.isDirty = true
      cam.resizeCameraTexture(Size(width: w, height: h))

iterator getCameras*(game: Game): Camera =
  for cam in game.cameras:
    yield cam

proc getCameraWithId*(game: Game, camId: CameraId): Camera =
  for cam in game.cameras:
    if cam.id == camId:
      return cam
  return nil

proc getFirstCameraFromMask*(game: Game, camId: CameraMask): Camera =
  var firstId = Camera1
  for id in camId:
    firstId = id
    break
  for cam in game.cameras:
    if cam.id == firstId:
      return cam
  return nil

import std/options
import ../../base_types
import ../../utils
import ../../matrices
import math
from raylib as ray import nil

var lastGenNameNumber: uint32 = 0 

type ContentWidget* = ref object of Widget
  ## A component that clips the child's drawing to ContentWidget's size with clipping
  ## Only first child with Widget is taken into account
  contentOffsetX: int32
  contentOffsetY: int32
  contentMinSize: Size ## Content minimum size computed in calculateMinSize()
  contentSize: Size ## Content size computed in updateLayout
  onContentSizeChanged*: proc(comp: ContentWidget)
  onContentOffsetXChanged*: proc(comp: ContentWidget)
  onContentOffsetYChanged*: proc(comp: ContentWidget)

proc newContentWidget*(parentNode: Node, name: string): ContentWidget =
  result = new(ContentWidget)
  initWidget(result, generateName(name, "ContentWidget", lastGenNameNumber))
  result.isClipChildren = true
  result.widthFactor = 1
  result.heightFactor = 1
  if not parentNode.isNil:
    parentNode.addComponent(result)

proc newNodeWithContentWidget*(parentNode: Node, widgetName: string = ""): tuple[node: Node, widget: ContentWidget] =
  ## Shortcut create widget with node and add it to parent node
  result.node = newNode()
  result.widget = newContentWidget(result.node, widgetName)
  if not parentNode.isNil:
    parentNode.addChild(result.node)

proc contentSize*(comp: ContentWidget): Size =
  return comp.contentSize

proc contentOffsetX*(comp: ContentWidget): int32 =
  return comp.contentOffsetX

proc `contentOffsetX=`*(comp: ContentWidget, newContentOffset: int32) =
  if comp.contentOffsetX == newContentOffset:
    return
  comp.contentOffsetX = newContentOffset
  if not comp.onContentOffsetXChanged.isNil:
    comp.onContentOffsetXChanged(comp)

proc contentOffsetY*(comp: ContentWidget): int32 =
  return comp.contentOffsetY

proc `contentOffsetY=`*(comp: ContentWidget, newContentOffset: int32) =
  if comp.contentOffsetY == newContentOffset:
    return
  comp.contentOffsetY = newContentOffset
  if not comp.onContentOffsetYChanged.isNil:
    comp.onContentOffsetYChanged(comp)

method calculateMinSize*(comp: ContentWidget) =
  comp.minSize = Size(
    width: 50 + comp.padding.left + comp.padding.right,
    height: 50 + comp.padding.top + comp.padding.bottom,
  )
  applyMinMaxConstraint(comp.minSize, comp.minConstraint, comp.maxConstraint)

  # calculate minimum child minimum size
  if comp.parent.isNil:
    return

  let child = comp.parent.getFirstChildWithWidget()
  if child.isSome:
    let (childNode, childComp) = child.get()
    childComp.calculateMinSize
    comp.contentMinSize = childComp.minSize
  else:
    comp.contentMinSize = Size(width: 0, height: 0)

method updateLayout*(comp: ContentWidget, availableSize: Size) =
  var newSize = availableSize
  applyMinMaxConstraint(newSize, comp.minConstraint, comp.maxConstraint)

  let parent = comp.parent

  if parent.isNil:
    # no parent Node so just return
    return

  var contentSizeChanged = false
  let child = comp.parent.getFirstChildWithWidget()
  if child.isSome:
    let (childNode, childComp) = child.get()
    childNode.x = float32(comp.padding.left + comp.contentOffsetX)
    childNode.y = float32(comp.padding.top + comp.contentOffsetY)

    # when newSize is bigger than contentMinSize, check child factor's and if they 
    # are greater than zero increase contentSize otherwise its simply contentMinSize

    var childSize = comp.contentMinSize
    # width
    if newSize.width - comp.padding.left - comp.padding.right > comp.contentMinSize.width and
        childComp.widthFactor > 0:
      childSize.width = newSize.width - comp.padding.left - comp.padding.right
    if newSize.height - comp.padding.top - comp.padding.bottom >
        comp.contentMinSize.height and childComp.heightFactor > 0:
      childSize.height = newSize.height - comp.padding.top - comp.padding.bottom
    childComp.size = childSize
    if comp.contentSize != childSize:
      comp.contentSize = childSize
      contentSizeChanged = true
    childComp.updateLayout(childComp.size)
  comp.size = newSize
  if contentSizeChanged and (not comp.onContentSizeChanged.isNil):
    comp.onContentSizeChanged(comp)
  echo "ContentWidget size: ", comp.size

method draw*(comp: ContentWidget, camera: Camera) =
  discard

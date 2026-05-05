import std/options
import ../../base_types
import ../../matrices
import math
from raylib as ray import nil

type ContentOffsetView* = ref object of UiComponent
  ## A component that clips the child's drawing to ContentOffsetView size with clipping
  ## Only first child with UiComponent is taken into account
  contentOffsetX: int32
  contentOffsetY: int32
  contentMinSize: Size ## Content minimum size computed in calculateMinSize()
  contentSize: Size ## Content size computed in updateLayout

proc newContentOffsetView*(name: string): ContentOffsetView =
  result = new(ContentOffsetView)
  result.initUiComponent(name)

method calculateMinSize*(comp: ContentOffsetView) =
  comp.minSize = Size(
    width: 50 + comp.padding.left + comp.padding.right,
    height: 50 + comp.padding.top + comp.padding.bottom,
  )
  applyMinMaxConstraint(comp.minSize, comp.minConstraint, comp.maxConstraint)

  # calculate minimum child minimum size
  if comp.parent.isNil:
    return

  let child = comp.parent.getFirstChildWithUiComponent()
  if child.isSome:
    let (childNode, childComp) = child.get()
    childComp.calculateMinSize
    comp.contentMinSize = childComp.minSize
  else:
    comp.contentMinSize = Size(width: 0, height: 0)

method updateLayout*(comp: ContentOffsetView, availableSize: Size) =
  var newSize = availableSize
  applyMinMaxConstraint(newSize, comp.minConstraint, comp.maxConstraint)

  let parent = comp.parent

  if parent.isNil:
    # no parent Node so just return
    return

  let child = comp.parent.getFirstChildWithUiComponent()
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
    comp.contentSize = childSize
    childComp.updateLayout(childComp.size)
  comp.size = newSize

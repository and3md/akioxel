import std/options
import ../../base_types
import ../../matrices
import math
from raylib as ray import nil

type
  ContentOffsetView* = ref object of UiComponent
    ## A component that clips the child's drawing to ContentOffsetView size with clipping
    ## Only first child with UiComponent is taken into account
    contentOffsetX: int32
    contentOffsetY: int32
    contentMinSize: Size ## Content minimum size computed in calculateMinSize()
    contentSize: Size ## Content size computed in updateLayout
  
method calculateMinSize*(comp: ContentOffsetView) =  
  comp.minSize = Size(width: 50 + comp.padding.left + comp.padding.right, height: 50 + comp.padding.top + comp.padding.bottom)

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


import ../../base_types
import ../../colors
import ../../matrices
import math
import sequtils
from raylib as ray import nil

type VLayout = ref object of UiComponent
  spacing: int32

proc newVLayout*(name: string): VLayout =
  result = new(VLayout)
  initUiComponent(result, name)
  result.spacing = 2

proc spacing*(comp: VLayout): int32 =
  return comp.spacing

proc `spacing=`*(comp: VLayout, newSpacingValue: int32) =
  if comp.spacing == newSpacingValue:
    return
  comp.spacing = newSpacingValue
  comp.uiNeedsSizeUpdate

method draw*(comp: VLayout, camera: Camera) =
  discard

method updateSize*(comp: VLayout, availableSize: Size) =
  ## Method to update size with children, we runt this only on root ui node
  ## Children are calculated recursively

  var newSize = availableSize
  applyMinMaxSize(newSize, comp.minSize, comp.maxSize)
  let parent = comp.parent

  # Phase 1: Update children size
  if parent.isNil:
    # no parent Node so just return
    return

  var children: seq[tuple[node: Node, comp: UiComponent]]
  for r in parent.getChildrenWithUi:
    if r.comp.isExisting:
      children.add(r)
      r.comp.updateSize(availableSize)

  # Phase 2: Set position and calculate used space without 
  var usedSpace: int32 = 0
  var heightFactorSum: int32 = 0
  var y: int32 = 0
  var wasFirstChild = false

  for r in children:
    if wasFirstChild:
      usedSpace += comp.spacing
    else:
      wasFirstChild = true  
    r.node.x = 0'f32 # temporary simplification
    r.node.y = float32(y + usedSpace)
    usedSpace += r.comp.calculatedMinSize.height
    heightFactorSum += r.comp.heightFactor

  # Phase 3: Expand children to use remaining space - TODO

  newSize.height = usedSpace
  echo "vlayout newSize ", newSize
  if comp.size == newSize:
    return
  comp.size = newSize
  parent.makeDirty

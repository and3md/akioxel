import ../../base_types
import ../../colors
import ../../matrices
import math
import sequtils
from raylib as ray import nil

type
  VAlignment {.pure.} = enum
    Top
    Center
    Bottom

  HAlignment {.pure.} = enum
    Left
    Center
    Right

  VLayout = ref object of UiComponent
    spacing: int32
    vAlignment: VAlignment
    hAlignment: HAlignment

proc newVLayout*(name: string): VLayout =
  result = new(VLayout)
  initUiComponent(result, name)
  result.spacing = 2
  result.vAlignment = VAlignment.Center
  result.hAlignment = HAlignment.Center

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
    # height:
    r.node.y = float32(y + usedSpace)
    usedSpace += r.comp.calculatedMinSize.height
    heightFactorSum += r.comp.heightFactor
    # width:
    # update width based on width factor
    if r.comp.widthFactor > 0:
      var size = r.comp.size
      size.width = max(r.comp.calculatedMinSize.width, newSize.width)
      size.width = max(size.width, r.comp.maxSize.width)
      r.comp.size = size
    case comp.hAlignment:
      of HAlignment.Left:
        r.node.x = 0'f32
      of HAlignment.Right:
        r.node.x = max(0, newSize.width - r.comp.size.width).float32
      of HAlignment.Center:
        r.node.x = max(0, ((newSize.width - r.comp.size.width) div 2).float32).float32

  # Phase 3: Expand children to use remaining space
  var remainingHeight = newSize.height - usedSpace
  if remainingHeight > 0:
    # calculate space per one height factor
    let spacePerHeightFactor = int32(remainingHeight / heightFactorSum)
    # iterate over children and add space
    wasFirstChild = false
    var deltaY:int32 = 0 
    for r in children:
      r.node.y = r.node.y + deltaY.float32
      if r.comp.heightFactor > 0:
        let extraHeight = spacePerHeightFactor * r.comp.heightFactor
        var size = r.comp.size
        size.height += extraHeight
        r.comp.size = size
        deltaY += spacePerHeightFactor * r.comp.heightFactor

  newSize.height = usedSpace
  echo "vlayout newSize ", newSize
  if comp.size == newSize:
    return
  comp.size = newSize
  parent.makeDirty

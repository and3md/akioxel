import ../../base_types
import ../../colors
import ../../matrices
import math
import sequtils
from raylib as ray import nil

type
  VAlignment* {.pure.} = enum
    Top
    Center
    Bottom

  HAlignment* {.pure.} = enum
    Left
    Center
    Right

  VLayout = ref object of UiComponent
    spacing: int32
    vAlignment: VAlignment
    hAlignment: HAlignment
    usedSpace: int32 = 0 ## Used space for calculated min size
    heightFactorSum: int32 = 0 ## Sum of height factors
    maxWidth: int32 = 0 ## Max width for calculated min size
    widthFactorSum: int32 = 0

proc newVLayout*(name: string): VLayout =
  result = new(VLayout)
  initUiComponent(result, name)
  result.spacing = 2
  result.vAlignment = VAlignment.Center
  result.hAlignment = HAlignment.Center

proc vAlignment*(comp: VLayout): VAlignment =
  return comp.vAlignment

proc `vAlignment=`*(comp: VLayout, newValue: VAlignment) =
  if comp.vAlignment == newValue:
    return
  comp.vAlignment = newValue
  comp.uiNeedsSizeUpdate

proc hAlignment*(comp: VLayout): HAlignment =
  return comp.hAlignment

proc `hAlignment=`*(comp: VLayout, newValue: HAlignment) =
  if comp.hAlignment == newValue:
    return
  comp.hAlignment = newValue
  comp.uiNeedsSizeUpdate

proc spacing*(comp: VLayout): int32 =
  return comp.spacing

proc `spacing=`*(comp: VLayout, newSpacingValue: int32) =
  if comp.spacing == newSpacingValue:
    return
  comp.spacing = newSpacingValue
  comp.uiNeedsSizeUpdate

method draw*(comp: VLayout, camera: Camera) =
  discard

method calculateMinSize*(comp: VLayout) =
  # Reset values
  comp.usedSpace = 0
  comp.heightFactorSum = 0
  comp.widthFactorSum = 0
  comp.maxWidth = 0

  var newSize = Size(width: 0, height: 0)
  let parent = comp.parent

  # Phase 1: Calculate children min size
  if parent.isNil:
    # no parent Node so just return
    return

  var wasFirstChild = false
  for r in parent.getChildrenWithUi:
    if not r.comp.isExisting:
      continue

    r.comp.calculateMinSize

    if wasFirstChild:
      comp.usedSpace += comp.spacing
    else:
      comp.usedSpace += comp.padding.top
      wasFirstChild = true

    comp.usedSpace += r.comp.minSize.height
    comp.heightFactorSum += r.comp.heightFactor
    comp.maxWidth = max(
      comp.maxWidth,
      r.comp.minSize.width + r.comp.padding.left + r.comp.padding.right,
    )
    comp.widthFactorSum += r.comp.widthFactor

  # Add bottom padding
  comp.usedSpace += comp.padding.bottom

  newSize.width = comp.maxWidth
  newSize.height = comp.usedSpace
  comp.minSize = newSize

method updateLayout*(comp: VLayout, availableSize: Size) =
  ## Method to set size, alignment with children, we runt this only on root ui node
  ## Children are calculated recursively

  var newSize = availableSize
  applyMinMaxConstraint(newSize, comp.minConstraint, comp.maxConstraint)
  let parent = comp.parent

  # Phase 1: Get excess size
  if parent.isNil:
    # no parent Node so just return
    return

  var remainingHeight = newSize.height - comp.usedSpace
  let spacePerHeightFactor =
    if remainingHeight > 0:
      int32(remainingHeight / comp.heightFactorSum)
    else:
      0

  var y = comp.padding.top
  var haveExpanding = comp.heightFactorSum > 0

  if not haveExpanding and remainingHeight > 0:
    # No expanding so set vertical alignment
    case comp.vAlignment
    of VAlignment.Top:
      discard
    of VAlignment.Center:
      y += (remainingHeight / 2).int32
    of VAlignment.Bottom:
      y += remainingHeight

  var children: seq[tuple[node: Node, comp: UiComponent]]
  for r in parent.getChildrenWithUi:
    if not r.comp.isExisting:
      continue
    children.add(r)

  # width and horizontal alignment
  var wasFirstChild = false
  for r in children:
    if wasFirstChild:
      y += comp.spacing
    else:
      wasFirstChild = true

    r.node.y = y.float32
    # calculate height
    var childHeight = r.comp.minSize.height
    if r.comp.heightFactor > 0:
      childHeight += spacePerHeightFactor * r.comp.heightFactor
    # height constraints
    if r.comp.maxConstraint.height != 0:
      childHeight = min(childHeight, r.comp.maxConstraint.height)
    childHeight = max(childHeight, r.comp.minConstraint.height)

    # calcualte width
    var childWidth = r.comp.minSize.width
    if r.comp.widthFactor > 0:
      childWidth = newSize.width - comp.padding.left - comp.padding.right
    # width constraints
    if r.comp.maxConstraint.width != 0:
      childWidth = min(childWidth, r.comp.maxConstraint.width)
    childWidth = max(childWidth, r.comp.minConstraint.width)

    if r.comp.widthFactor == 0 or childWidth != newSize.width:
      case comp.hAlignment
      of HAlignment.Left:
        r.node.x = comp.padding.right.float32
      of HAlignment.Center:
        r.node.x = (
          (
            newSize.width - comp.padding.left - comp.padding.right -
            r.comp.minSize.width
          ) / 2
        ).float32
      of HAlignment.Right:
        r.node.x = (
          newSize.width - comp.padding.left - comp.padding.right -
          r.comp.minSize.width
        ).float32
    else:
      r.node.x = comp.padding.right.float32

    r.comp.size = Size(width: childWidth, height: childHeight)
    # layout sub widget
    r.comp.updateLayout(r.comp.size)

    y += childHeight

  if comp.size == newSize:
    return
  comp.size = newSize
  parent.makeDirty

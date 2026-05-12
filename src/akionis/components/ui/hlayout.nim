import ../../base_types
import ../../utils
import math
from raylib as ray import nil
import alignment

var lastGenNameNumber: uint32 = 0 

type
  HLayout = ref object of Widget
    spacing: int32
    vAlignment: VAlignment
    hAlignment: HAlignment
    usedSpace: int32 = 0 ## Used space for calculated min size
    heightFactorSum: int32 = 0 ## Sum of height factors
    maxHeight: int32 = 0 ## Max width for calculated min size
    widthFactorSum: int32 = 0

proc newHLayout*(parentNode: Node, name: string = ""): HLayout =
  result = new(HLayout)
  initWidget(result, generateName(name, "HLayout", lastGenNameNumber))
  result.spacing = 2
  result.vAlignment = VAlignment.Center
  result.hAlignment = HAlignment.Center
  if not parentNode.isNil:
    parentNode.addComponent(result)

proc newNodeWithHLayout(parentNode: Node, widgetName: string =""): tuple[node: Node, widget: HLayout] =
  ## Shortcut create widget with node and add it to parent node
  result.node = newNode()
  result.widget = newHLayout(result.node, widgetName)
  if not parentNode.isNil:
    parentNode.addChild(result.node)

proc vAlignment*(comp: HLayout): VAlignment =
  return comp.vAlignment

proc `vAlignment=`*(comp: HLayout, newValue: VAlignment) =
  if comp.vAlignment == newValue:
    return
  comp.vAlignment = newValue
  comp.uiNeedsLayoutUpdate

proc hAlignment*(comp: HLayout): HAlignment =
  return comp.hAlignment

proc `hAlignment=`*(comp: HLayout, newValue: HAlignment) =
  if comp.hAlignment == newValue:
    return
  comp.hAlignment = newValue
  comp.uiNeedsLayoutUpdate

proc spacing*(comp: HLayout): int32 =
  return comp.spacing

proc `spacing=`*(comp: HLayout, newSpacingValue: int32) =
  if comp.spacing == newSpacingValue:
    return
  comp.spacing = newSpacingValue
  comp.uiNeedsLayoutUpdate

method draw*(comp: HLayout, camera: Camera) =
  discard

method calculateMinSize*(comp: HLayout) =
  # Reset values
  comp.usedSpace = 0
  comp.heightFactorSum = 0
  comp.widthFactorSum = 0
  comp.maxHeight = 0

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
      comp.usedSpace += comp.padding.left
      wasFirstChild = true

    comp.usedSpace += r.comp.minSize.width
    comp.widthFactorSum += r.comp.widthFactor
    comp.maxHeight = max(
      comp.maxHeight,
      r.comp.minSize.height + r.comp.padding.top + r.comp.padding.bottom,
    )
    comp.heightFactorSum += r.comp.widthFactor

  # Add right padding
  comp.usedSpace += comp.padding.right

  newSize.width = comp.usedSpace
  newSize.height = comp.maxHeight
  comp.minSize = newSize

method updateLayout*(comp: HLayout, availableSize: Size) =
  ## Method to set size, alignment with children, we run this only on root ui node
  ## Children are calculated recursively

  var newSize = availableSize
  applyMinMaxConstraint(newSize, comp.minConstraint, comp.maxConstraint)
  let parent = comp.parent

  # Phase 1: Get excess size
  if parent.isNil:
    # no parent Node so just return
    return

  var remainingWidth = newSize.width - comp.usedSpace
  let spacePerWidthFactor =
    if remainingWidth > 0:
      int32(remainingWidth / comp.widthFactorSum)
    else:
      0

  var x = comp.padding.left
  var haveExpanding = comp.widthFactorSum > 0

  if not haveExpanding and remainingWidth > 0:
    # No expanding so set vertical alignment
    case comp.hAlignment
    of HAlignment.Left:
      discard
    of HAlignment.Center:
      x += (remainingWidth / 2).int32
    of HAlignment.Right:
      x += remainingWidth

  var children: seq[tuple[node: Node, comp: Widget]]
  for r in parent.getChildrenWithUi:
    if not r.comp.isExisting:
      continue
    children.add(r)

  # width and horizontal alignment
  var wasFirstChild = false
  for r in children:
    if wasFirstChild:
      x += comp.spacing
    else:
      wasFirstChild = true

    r.node.x = x.float32
    # calculate width
    var childWidth = r.comp.minSize.width
    if r.comp.widthFactor > 0:
      childWidth += spacePerWidthFactor * r.comp.widthFactor
    # width constraints
    if r.comp.maxConstraint.width != 0:
      childWidth = min(childWidth, r.comp.maxConstraint.width)
    childWidth = max(childWidth, r.comp.minConstraint.width)

    # calcualte height
    var childHeight = r.comp.minSize.height
    if r.comp.heightFactor > 0:
      childHeight = newSize.height - comp.padding.top - comp.padding.bottom
    # height constraints
    if r.comp.maxConstraint.height != 0:
      childHeight = min(childHeight, r.comp.maxConstraint.height)
    childHeight = max(childHeight, r.comp.minConstraint.height)

    if r.comp.heightFactor == 0 or childHeight != newSize.height:
      case comp.vAlignment
      of VAlignment.Top:
        r.node.y = comp.padding.top.float32
      of VAlignment.Center:
        r.node.y = (
          (
            newSize.height - comp.padding.top - comp.padding.bottom -
            r.comp.minSize.height
          ) / 2
        ).float32
      of VAlignment.Bottom:
        r.node.y = (
          newSize.height - comp.padding.top - comp.padding.bottom -
          r.comp.minSize.height
        ).float32
    else:
      r.node.y = comp.padding.top.float32

    r.comp.size = Size(width: childWidth, height: childHeight)
    # layout sub widget
    r.comp.updateLayout(r.comp.size)

    x += childWidth

  if comp.size == newSize:
    return
  comp.size = newSize
  parent.makeDirty

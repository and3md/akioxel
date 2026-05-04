import ../../base_types
import math
from raylib as ray import nil
import alignment

type
  BorderLayoutPosition* {.pure.} = enum
    Center
    Right
    Bottom
    Left
    Top

  BorderLayoutPositions = set[BorderLayoutPosition]

  BorderLayout = ref object of UiComponent
    ## The layout that the first child takes as the center, the next as the right side,
    ## the next as the bottom side, the next as the left side, the next as the top side,
    ##
    ## To skip any side insert child with isExisting = false
    spacing: int32 ## Space between components
    vAlignment: VAlignment
    hAlignment: HAlignment
    usedWidth: array[BorderLayoutPosition, int32] ## Width used by minimal size in rows
    usedHeight: array[BorderLayoutPosition, int32] ## Height used by minimal size in cols
    heightFactorSum: array[BorderLayoutPosition, int32] ## Sum of height factors in cols
    widthFactorSum: array[BorderLayoutPosition, int32] ## Sum of width factors in rows
    widestRow: BorderLayoutPosition ## Top, Center or Bottom
    highestColumn: BorderLayoutPosition ## Left, Center or Right

proc newBorderLayout*(name: string): BorderLayout =
  result = new (BorderLayout)
  initUiComponent(result, name)
  result.spacing = 2

proc vAlignment*(comp: BorderLayout): VAlignment =
  return comp.vAlignment

proc `vAlignment=`*(comp: BorderLayout, newValue: VAlignment) =
  if comp.vAlignment == newValue:
    return
  comp.vAlignment = newValue
  comp.uiNeedsLayoutUpdate

proc hAlignment*(comp: BorderLayout): HAlignment =
  return comp.hAlignment

proc `hAlignment=`*(comp: BorderLayout, newValue: HAlignment) =
  if comp.hAlignment == newValue:
    return
  comp.hAlignment = newValue
  comp.uiNeedsLayoutUpdate

proc spacing*(comp: BorderLayout): int32 =
  return comp.spacing

proc `spacing=`*(comp: BorderLayout, newSpacingValue: int32) =
  if comp.spacing == newSpacingValue:
    return
  comp.spacing = newSpacingValue
  comp.uiNeedsLayoutUpdate

method draw*(comp: BorderLayout, camera: Camera) =
  discard

method calculateMinSize*(comp: BorderLayout) =
  # Reset values
  for pos in BorderLayoutPosition:
    comp.usedWidth[pos] = 0
    comp.usedHeight[pos] = 0
    comp.heightFactorSum[pos] = 0
    comp.widthFactorSum[pos] = 0

  var newSize = Size(width: 0, height: 0)
  let parent = comp.parent

  # Phase 1: Calculate children min size
  if parent.isNil:
    # no parent Node so just return
    return

  var currentPos: BorderLayoutPosition = BorderLayoutPosition.Center
  var childrenArray: array[BorderLayoutPosition, tuple[node: Node, comp: UiComponent]]
  var availablePositions: BorderLayoutPositions
  for r in parent.getChildrenWithUi:
    if not r.comp.isExisting:
      continue
    childrenArray[currentPos] = r
    availablePositions.incl(currentPos)
    if currentPos == high BorderLayoutPosition:
      break
    inc currentPos
    r.comp.calculateMinSize

  # calculate used width - for 3 rows 
  # for first row only BorderLayoutPosition.Top
  var calcualtedRow = BorderLayoutPosition.Top
  if BorderLayoutPosition.Top in availablePositions:
    comp.usedWidth[calcualtedRow] = comp.padding.left
    comp.usedWidth[calcualtedRow] += comp.padding.right
    comp.usedWidth[calcualtedRow] += childrenArray[BorderLayoutPosition.Top].comp.minSize.width
    comp.widthFactorSum[calcualtedRow] = childrenArray[BorderLayoutPosition.Top].comp.widthFactor
    if BorderLayoutPosition.Left in availablePositions:
      comp.usedWidth[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Left].comp.minSize.width
    if BorderLayoutPosition.Right in availablePositions:
      comp.usedWidth[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Right].comp.minSize.width

  # for second row BorderLayoutPosition.Left, BorderLayoutPosition.Center, BorderLayoutPosition.Right
  calcualtedRow = BorderLayoutPosition.Center
  comp.usedWidth[calcualtedRow] = comp.padding.left
  var wasFirst = false
  for pos in @[
    BorderLayoutPosition.Left, BorderLayoutPosition.Center, BorderLayoutPosition.Right
  ]:
    if pos in availablePositions:
      if not childrenArray[pos].comp.isExisting:
        continue
      if wasFirst:
        comp.usedWidth[calcualtedRow] += comp.spacing
      else:
        wasFirst = true
      comp.usedWidth[calcualtedRow] += childrenArray[pos].comp.minSize.width
      comp.widthFactorSum[calcualtedRow] += childrenArray[pos].comp.widthFactor
  comp.usedWidth[calcualtedRow] += comp.padding.right

  # for third row - BorderLayoutPosition.Bottom
  calcualtedRow = BorderLayoutPosition.Bottom
  if BorderLayoutPosition.Bottom in availablePositions:
    comp.usedWidth[calcualtedRow] = comp.padding.left
    comp.usedWidth[calcualtedRow] += comp.padding.right
    comp.usedWidth[calcualtedRow] += childrenArray[BorderLayoutPosition.Bottom].comp.minSize.width
    comp.widthFactorSum[calcualtedRow] = childrenArray[BorderLayoutPosition.Bottom].comp.widthFactor
    if BorderLayoutPosition.Left in availablePositions:
      comp.usedWidth[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Left].comp.minSize.width
    if BorderLayoutPosition.Right in availablePositions:
      comp.usedWidth[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Right].comp.minSize.width

  # calculate used height - for three columns
  # for first column only BorderLayoutPosition.Left
  var calculatedColumn = BorderLayoutPosition.Left
  if BorderLayoutPosition.Left in availablePositions:
    comp.usedHeight[calculatedColumn] = comp.padding.top
    comp.usedHeight[calculatedColumn] += comp.padding.bottom
    comp.usedHeight[calculatedColumn] += childrenArray[BorderLayoutPosition.Left].comp.minSize.height
    comp.heightFactorSum[calculatedColumn] = childrenArray[BorderLayoutPosition.Left].comp.heightFactor
    if BorderLayoutPosition.Top in availablePositions:
      comp.usedHeight[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Top].comp.minSize.height
    if BorderLayoutPosition.Bottom in availablePositions:
      comp.usedHeight[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Bottom].comp.minSize.height


  # for second column BorderLayoutPosition.Top, BorderLayoutPosition.Center, BorderLayoutPosition.Bottom
  calculatedColumn = BorderLayoutPosition.Center
  comp.usedHeight[calculatedColumn] = comp.padding.top
  wasFirst = false
  for pos in @[
    BorderLayoutPosition.Top, BorderLayoutPosition.Center, BorderLayoutPosition.Bottom
  ]:
    if pos in availablePositions:
      if not childrenArray[pos].comp.isExisting:
        continue
      if wasFirst:
        comp.usedHeight[calculatedColumn] += comp.spacing
      else:
        wasFirst = true
      comp.usedHeight[calculatedColumn] += childrenArray[pos].comp.minSize.height
      comp.heightFactorSum[calculatedColumn] += childrenArray[pos].comp.heightFactor
  comp.usedHeight[calculatedColumn] += comp.padding.bottom

  # for third column only BorderLayoutPosition.Right
  calculatedColumn = BorderLayoutPosition.Right
  if BorderLayoutPosition.Right in availablePositions:
    comp.usedHeight[calculatedColumn] = comp.padding.top
    comp.usedHeight[calculatedColumn] += comp.padding.bottom
    comp.usedHeight[calculatedColumn] += childrenArray[BorderLayoutPosition.Right].comp.minSize.height
    comp.heightFactorSum[calculatedColumn] = childrenArray[BorderLayoutPosition.Right].comp.heightFactor
    if BorderLayoutPosition.Top in availablePositions:
      comp.usedHeight[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Top].comp.minSize.height
    if BorderLayoutPosition.Bottom in availablePositions:
      comp.usedHeight[calcualtedRow] += comp.spacing + childrenArray[BorderLayoutPosition.Bottom].comp.minSize.height

  if comp.usedWidth[BorderLayoutPosition.Top] > comp.usedWidth[BorderLayoutPosition.Center] and
    comp.usedWidth[BorderLayoutPosition.Top] > comp.usedWidth[BorderLayoutPosition.Bottom]:
      comp.widestRow = BorderLayoutPosition.Top
  else:
    if comp.usedWidth[BorderLayoutPosition.Center] > comp.usedWidth[BorderLayoutPosition.Top] and
      comp.usedWidth[BorderLayoutPosition.Center] > comp.usedWidth[BorderLayoutPosition.Bottom]:
      comp.widestRow = BorderLayoutPosition.Center
    else:
      comp.widestRow = BorderLayoutPosition.Bottom
 
  if comp.usedHeight[BorderLayoutPosition.Left] > comp.usedHeight[BorderLayoutPosition.Center] and
    comp.usedHeight[BorderLayoutPosition.Left] > comp.usedHeight[BorderLayoutPosition.Right]:
      comp.highestColumn = BorderLayoutPosition.Left
  else:
    if comp.usedHeight[BorderLayoutPosition.Center] > comp.usedHeight[BorderLayoutPosition.Left] and
      comp.usedHeight[BorderLayoutPosition.Center] > comp.usedHeight[BorderLayoutPosition.Right]:
        comp.highestColumn = BorderLayoutPosition.Center
    else:
      comp.highestColumn = BorderLayoutPosition.Right

  newSize.width = comp.usedWidth[comp.widestRow]
  newSize.height = comp.usedHeight[comp.highestColumn]
  comp.minSize = newSize

method updateLayout*(comp: BorderLayout, availableSize: Size) =
  ## Method to set size, alignment with children, we run this only on root ui node
  ## Children are calculated recursively

  var newSize = availableSize
  applyMinMaxConstraint(newSize, comp.minConstraint, comp.maxConstraint)
  let parent = comp.parent

  if parent.isNil:
    # no parent Node so just return
    return

  # Get available positions and children array
  var currentPos: BorderLayoutPosition = BorderLayoutPosition.Center
  var childrenArray: array[BorderLayoutPosition, tuple[node: Node, comp: UiComponent]]
  var availablePositions: BorderLayoutPositions
  for r in parent.getChildrenWithUi:
    if not r.comp.isExisting:
      continue
    childrenArray[currentPos] = r
    availablePositions.incl(currentPos)
    if currentPos == high BorderLayoutPosition:
      break
    inc currentPos

  # Get the biggest position in horzontal space
  var biggestMinWidthHorizontal: BorderLayoutPositions
  if BorderLayoutPosition.Left in availablePositions:
    biggestMinWidthHorizontal.incl(BorderLayoutPosition.Left)
  
  if childrenArray[BorderLayoutPosition.Top].comp.minSize.width > childrenArray[BorderLayoutPosition.Center].comp.minSize.width and
    childrenArray[BorderLayoutPosition.Top].comp.minSize.width > childrenArray[BorderLayoutPosition.Bottom].comp.minSize.width:
      biggestMinWidthHorizontal.incl(BorderLayoutPosition.Top)
  else:
    if childrenArray[BorderLayoutPosition.Center].comp.minSize.width > childrenArray[BorderLayoutPosition.Top].comp.minSize.width and
      childrenArray[BorderLayoutPosition.Center].comp.minSize.width > childrenArray[BorderLayoutPosition.Bottom].comp.minSize.width:
      biggestMinWidthHorizontal.incl(BorderLayoutPosition.Center)
    else:
      biggestMinWidthHorizontal.incl(BorderLayoutPosition.Bottom)

  if BorderLayoutPosition.Right in availablePositions:
    biggestMinWidthHorizontal.incl(BorderLayoutPosition.Right)

  # biggest min size is the widest used space 
  let biggestMinWidth = comp.minSize.width
  # calculate free space and 
  var remainingWidthInWidestPlace = newSize.width - biggestMinWidth
  var widestRowWidthFactorSum = comp.widthFactorSum[comp.widestRow]
  
  var spacePerWidthFactorWidestRow = 
    if widestRowWidthFactorSum > 0 and remainingWidthInWidestPlace > 0:
      int32(remainingWidthInWidestPlace / widestRowWidthFactorSum)
    else:
      0

  let maxWidth = newSize.width - comp.padding.left - comp.padding.right
  # Now set all elements width
  var calculatedWidth: array[BorderLayoutPosition, int32]

  if BorderLayoutPosition.Left in availablePositions:
    let leftComp = childrenArray[BorderLayoutPosition.Left].comp
    if leftComp.widthFactor == 0 or remainingWidthInWidestPlace == 0:
      calculatedWidth[BorderLayoutPosition.Left] = leftComp.minSize.width
    else:
      calculatedWidth[BorderLayoutPosition.Left] = leftComp.minSize.width + spacePerWidthFactorWidestRow * leftComp.widthFactor
      # TODO constraints

  if BorderLayoutPosition.Right in availablePositions:
    let rightComp = childrenArray[BorderLayoutPosition.Right].comp
    if rightComp.widthFactor == 0 or remainingWidthInWidestPlace == 0:
      calculatedWidth[BorderLayoutPosition.Right] = rightComp.minSize.width
    else:
      calculatedWidth[BorderLayoutPosition.Right] = rightComp.minSize.width + spacePerWidthFactorWidestRow * rightComp.widthFactor
      # TODO constraints

  # top, center, bottom components  width
  for pos in @[BorderLayoutPosition.Top, BorderLayoutPosition.Center, BorderLayoutPosition.Bottom]:
    if pos in availablePositions:
      let calculatedComp = childrenArray[pos].comp
      # if no widthFactor set to minSize.width
      if calculatedComp.widthFactor == 0:
        calculatedWidth[pos] = calculatedComp.minSize.width
      else:
        calculatedWidth[pos] = maxWidth
        if BorderLayoutPosition.Left in availablePositions:
          calculatedWidth[pos] -= calculatedWidth[BorderLayoutPosition.Left]
          calculatedWidth[pos] -= comp.spacing
        if BorderLayoutPosition.Right in availablePositions:
          calculatedWidth[pos] -= calculatedWidth[BorderLayoutPosition.Right]
          calculatedWidth[pos] -= comp.spacing
      # TODO constriants

  # now we have all widths, it's time for height
  # in this case analogously we start by calcuclating top and bottom
  # height then all between

  # biggest min size is the widest used space 
  let biggestMinHeight = comp.minSize.height
  # calculate free space and 
  var remainingHeightInHighestPlace = newSize.height - biggestMinHeight
  var highestColWidthFactorSum = comp.heightFactorSum[comp.highestColumn]
  
  var spacePerHeightFactorHighestCol = 
    if highestColWidthFactorSum > 0 and remainingHeightInHighestPlace > 0:
      int32(remainingHeightInHighestPlace / highestColWidthFactorSum)
    else:
      0

  let maxHeight = newSize.height - comp.padding.top - comp.padding.bottom
  
  var calculatedHeight: array[BorderLayoutPosition, int32]

  if BorderLayoutPosition.Top in availablePositions:
    let topComp = childrenArray[BorderLayoutPosition.Top].comp
    if topComp.heightFactor == 0 or remainingHeightInHighestPlace == 0:
      calculatedHeight[BorderLayoutPosition.Top] = topComp.minSize.height
    else:
      calculatedHeight[BorderLayoutPosition.Top] = topComp.minSize.height + spacePerHeightFactorHighestCol * topComp.heightFactor
      # TODO constraints

  if BorderLayoutPosition.Bottom in availablePositions:
    let bottomComp = childrenArray[BorderLayoutPosition.Right].comp
    if bottomComp.heightFactor == 0 or remainingHeightInHighestPlace == 0:
      calculatedHeight[BorderLayoutPosition.Bottom] = bottomComp.minSize.height
    else:
      calculatedHeight[BorderLayoutPosition.Bottom] = bottomComp.minSize.height + spacePerHeightFactorHighestCol * bottomComp.heightFactor
      # TODO constraints

  # left, center, right components height
  for pos in @[BorderLayoutPosition.Left, BorderLayoutPosition.Center, BorderLayoutPosition.Right]:
    if pos in availablePositions:
      let calculatedComp = childrenArray[pos].comp
      # if no heiightFactor set to comp minSize.height
      if calculatedComp.heightFactor == 0:
        calculatedHeight[pos] = calculatedComp.minSize.height
      else:
        calculatedHeight[pos] = maxHeight
        if BorderLayoutPosition.Top in availablePositions:
          calculatedHeight[pos] -= calculatedHeight[BorderLayoutPosition.Top]
          calculatedHeight[pos] -= comp.spacing
        if BorderLayoutPosition.Bottom in availablePositions:
          calculatedHeight[pos] -= calculatedHeight[BorderLayoutPosition.Bottom]
          calculatedHeight[pos] -= comp.spacing
        # TODO constriants

  # now use calculated sizes and positioning
  var x = comp.padding.left
  var y = comp.padding.top

  var haveExpandingWidth = false
  var haveExpandingHeight = false
  for pos in availablePositions:
    if comp.widthFactorSum[pos] > 0:
      haveExpandingWidth = true
    if comp.heightFactorSum[pos] > 0:
      haveExpandingHeight = true
    if haveExpandingWidth and haveExpandingHeight:
      break

  if not haveExpandingWidth and remainingWidthInWidestPlace > 0:
    # No expanding so set horizontal alignment
    case comp.hAlignment
    of HAlignment.Left:
      discard
    of HAlignment.Center:
      x += (remainingWidthInWidestPlace / 2).int32
    of HAlignment.Right:
      x += remainingWidthInWidestPlace

  if not haveExpandingHeight and remainingHeightInHighestPlace > 0:
    # No expanding so set vertical alignment
    case comp.vAlignment
    of VAlignment.Top:
      discard
    of VAlignment.Center:
      y += (remainingHeightInHighestPlace / 2).int32
    of VAlignment.Bottom:
      y += remainingHeightInHighestPlace

  # first x for left and y for top
  if BorderLayoutPosition.Left in availablePositions:
    let leftNode = childrenArray[BorderLayoutPosition.Left].node
    leftNode.x = x.float32
    x += calculatedWidth[BorderLayoutPosition.Left] + comp.spacing
  
  if BorderLayoutPosition.Top in availablePositions:
    let topChild = childrenArray[BorderLayoutPosition.Top]
    topChild.node.x = x.float32
    topChild.node.y = y.float32
    y += calculatedHeight[BorderLayoutPosition.Top] + comp.spacing
    topChild.comp.size = Size(width: calculatedWidth[BorderLayoutPosition.Top], height: calculatedHeight[BorderLayoutPosition.Top])
    topChild.comp.updateLayout(topChild.comp.size)

  var yForBottom = y
  # finish left child (egg, chicken problem)
  if BorderLayoutPosition.Left in availablePositions:
    let leftChild = childrenArray[BorderLayoutPosition.Left]
    leftChild.node.y = y.float32
    leftChild.comp.size = Size(width: calculatedWidth[BorderLayoutPosition.Left], height: calculatedHeight[BorderLayoutPosition.Left])
    leftChild.comp.updateLayout(leftChild.comp.size)
    yForBottom = max(yForBottom, y + comp.spacing + leftChild.comp.size.height)
  
  let xForBottom = x
  # center:
  if BorderLayoutPosition.Center in availablePositions:
    let centerChild = childrenArray[BorderLayoutPosition.Center]
    centerChild.node.x = x.float32
    centerChild.node.y = y.float32
    centerChild.comp.size = Size(width: calculatedWidth[BorderLayoutPosition.Center], height: calculatedHeight[BorderLayoutPosition.Center])
    centerChild.comp.updateLayout(centerChild.comp.size)
    x += calculatedWidth[BorderLayoutPosition.Center] + comp.spacing
    yForBottom = max(yForBottom, y + comp.spacing + centerChild.comp.size.height)
  else:
    echo "Center UI Component of BorderLayout should be always available."
  
  # right: 
  if BorderLayoutPosition.Right in availablePositions:
    let rightChild = childrenArray[BorderLayoutPosition.Right]
    rightChild.node.x = x.float32
    rightChild.node.y = y.float32
    rightChild.comp.size = Size(width: calculatedWidth[BorderLayoutPosition.Right], height: calculatedHeight[BorderLayoutPosition.Right])
    rightChild.comp.updateLayout(rightChild.comp.size)
    yForBottom = max(yForBottom, y + comp.spacing + rightChild.comp.size.height)

  # bottom:
  if BorderLayoutPosition.Bottom in availablePositions:
    let bottomChild = childrenArray[BorderLayoutPosition.Bottom]
    bottomChild.node.x = xForBottom.float32
    bottomChild.node.y = yForBottom.float32
    bottomChild.comp.size = Size(width: calculatedWidth[BorderLayoutPosition.Bottom], height: calculatedHeight[BorderLayoutPosition.Bottom])
    bottomChild.comp.updateLayout(bottomChild.comp.size)
    # update border right x when bottom width > center width
    if BorderLayoutPosition.Right in availablePositions:
      let rightChild = childrenArray[BorderLayoutPosition.Right]
      rightChild.node.x = max(rightChild.node.x, bottomChild.node.x + float32(bottomChild.comp.size.width + comp.spacing))

  if comp.size == newSize:
    return
  comp.size = newSize
  echo "Border layout size ", comp.size
  parent.makeDirty

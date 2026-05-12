import ../../base_types
import math
from raylib as ray import nil
import alignment
import border_layout
import scroll_bar_widget
import orientation
import content_widget

type ScrollLayout = ref object of BorderLayout
  scrollBar: array[Orientation, ScrollBarWidget]

proc updateScrollBars(comp: ContentWidget, vertScrollBar, horizScrollBar: ScrollBarWidget)


proc newNodeWithScrollArea*(parentNode: Node): tuple[node: Node, contentWidget: ContentWidget, borderLayout: BorderLayout] = 
  ## Combines some nodes and widgets to make scroll area
  ## 
  ## Result fields:
  ## - node - content widget node
  ## - contentWidget - inner ContentWidget component
  ## - borderLayout - outer BorderLayout component
  echo("create scroll area")
  let borderLayout = newNodeWithBorderLayout(parentNode)
  result.borderLayout = borderLayout.widget

  let contentWidget = newNodeWithContentWidget(borderLayout.node)
  result.node = contentWidget.node
  result.contentWidget = contentWidget.widget

  let vertScrollBar = newNodeWithScrollBarWidget(borderLayout.node, Orientation.Vertical)
  let horizScrollBar = newNodeWithScrollBarWidget(borderLayout.node, Orientation.Horizontal, "scrollBar")

  contentWidget.widget.onContentSizeChanged = proc(comp: ContentWidget) =
    updateScrollBars(comp, vertScrollBar.widget, horizScrollBar.widget)

  contentWidget.widget.onSizeChanged = proc(comp: Widget) =
    if comp of ContentWidget:
      updateScrollBars(ContentWidget(comp), vertScrollBar.widget, horizScrollBar.widget)
  
  vertScrollBar.widget.onValueChanged = proc(newValue: int32) =
    contentWidget.widget.contentOffsetY = -newValue

  horizScrollBar.widget.onValueChanged = proc(newValue: int32) =
    contentWidget.widget.contentOffsetX = -newValue

proc updateScrollBars(comp: ContentWidget, vertScrollBar, horizScrollBar: ScrollBarWidget) =
  var widthFits = comp.contentSize.width <= comp.size.width
  var heightFits = comp.contentSize.height <= comp.size.height
  if widthFits and heightFits:
    horizScrollBar.isExisting = false
    vertScrollBar.isExisting = false
    comp.contentOffsetX = 0
    comp.contentOffsetX = 0
  elif widthFits:
    # We need check width >= vertScrollBar.size.width + content width
    if comp.size.width >= vertScrollBar.size.width + comp.contentSize.width:
      horizScrollBar.isExisting = false
    else:
      horizScrollBar.isExisting = true
    vertScrollBar.isExisting = true
  elif heightFits:
    # We need check height >= horizScrollBar.size.height + content height
    if comp.size.height >= horizScrollBar.size.height + comp.contentSize.height:
      vertScrollBar.isExisting = false
    else:
      vertScrollBar.isExisting = true
    horizScrollBar.isExisting = true
  else:
    vertScrollBar.isExisting = true
    horizScrollBar.isExisting = true

  if vertScrollBar.isExisting == true:
    vertScrollBar.maxValue = comp.contentSize.height
    vertScrollBar.thumbSize = comp.size.height
    vertScrollBar.value = comp.contentOffsetY

  if horizScrollBar.isExisting == true:
    horizScrollBar.maxValue = comp.contentSize.width
    horizScrollBar.thumbSize = comp.size.width
    horizScrollBar.value = comp.contentOffsetX

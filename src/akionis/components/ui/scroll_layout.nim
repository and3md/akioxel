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

proc newScrollNode(parentNode: Node): tuple[node: Node, contentWidget: ContentWidget] = 
  echo("create scroll area")
  let borderLayout = newNodeWithBorderLayout(parentNode)
  result.node = borderLayout.node

  let contentWidget = newNodeWithContentWidget(borderLayout.node)

  let vertScrollBar = newNodeWithScrollBarWidget(borderLayout.node, Orientation.Vertical)
  let horizScrollBar = newNodeWithScrollBarWidget(borderLayout.node, Orientation.Horizontal, "scrollBar")

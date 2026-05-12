import ../../base_types
import math
from raylib as ray import nil
import alignment
import border_layout
import scroll_bar
import orientation
import content_offset_view

type ScrollLayout = ref object of BorderLayout
  scrollBar: array[Orientation, ScrollBar]

proc newScrollNode(parentNode: Node): tuple[node: Node, contentView: ContentOffsetView] = 
  echo("create scroll area")
  result.node = newNode(0,0,1,1,0)
  let borderLayout = newBorderLayout("scrollLayout")

  let vertScrollBarNode = newNode(0,0,1,1,0)
  let vertScrollBar = newScrollBar(Orientation.Vertical, "scrollBar")
  vertScrollBarNode.addComponent(vertScrollBar)
  result.node.addChild(vertScrollBarNode)
  let horizScrollBarNode = newNode(0,0,1,1,0)
  let horizScrollBar = newScrollBar(Orientation.Horizontal, "scrollBar")
  horizScrollBarNode.addComponent(horizScrollBar)
  result.node.addChild(horizScrollBarNode)



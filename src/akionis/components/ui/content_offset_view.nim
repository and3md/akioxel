import ../../base_types
import ../../matrices
import math
from raylib as ray import nil

type
  ContentOffsetView* = ref object of UiComponent
    ## A component that clips the child's drawing to ContentOffsetView size with clipping
    contentOffsetX: int32
    contentOffsetY: int32
  
  
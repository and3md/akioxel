import ../../base_types
import ../../colors
import ../../matrices
import button_state
import math
import ../../textures
from raylib as ray import nil

type ImageUiComp* = ref object of UiComponent
  texture: SharedTexture
  
# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.
import akionis/base_types
import akionis/game_loop
import akionis/matrices
import akionis/colors
import akionis/components/square

proc add*(x, y: int): int =
  ## Adds two numbers together.
  return x + y

export 
  matrices, colors, base_types, game_loop, square
  
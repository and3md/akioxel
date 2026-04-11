# This is just an example to get you started. Users of your library will
# import this file by writing ``import akioxel/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.

from raylib as ray import nil
import base_types

proc run*(game: Game, state: State) =
  ## Runs the game loop 
  
  game.openRootState(state)
  while not ray.windowShouldClose():
    game.updateGame(ray.getFrameTime())
    ray.beginDrawing()
    ray.clearBackground(ray.DarkGray)
    ray.endDrawing()



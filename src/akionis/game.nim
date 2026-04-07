# This is just an example to get you started. Users of your library will
# import this file by writing ``import akioxel/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.

from raylib as ray import nil

type Game* = ref object of RootObj
  title: string

var instance: Game

proc getGame*(): Game =
  if instance.isNil:
    raise newException(ValueError, "No game instance")
  return instance

proc initGame*(windowWidth, windowHeight: int32, title: string) =
  ## Initialises a new ``Game`` object.
  if instance.isNil:
    instance = Game(title: title)
    ray.initWindow(windowWidth, windowHeight, title)
  else:
    raise newException(ValueError, "Game already created")

proc run*(game: Game) =
  ## Runs the game loop 
  while not ray.windowShouldClose():
    ray.beginDrawing()
    ray.clearBackground(ray.DarkGray)
    ray.endDrawing()

proc title*(game: Game): string =
  return game.title

proc `title=`*(game: Game, newTitle: string) =
  ray.setWindowTitle(newTitle)
  game.title = newTitle

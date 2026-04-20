# State related things included to base_types

proc initState*(self: State, game: Game, name: string) =
  self.name = name
  self.rootNode = new(RootNode)
  self.rootNode.parentState = self
  self.game = game

method close*(state: State) =
  echo "Close state ", state.name

method update*(state: State, deltaTime: float32) =
  echo "Update in state ", state.name

method start*(state: State) =
  echo "Start state ", state.name

method stop*(state: State) =
  echo "Stop state ", state.name

proc doClose(state: State) =
  ## Takes care of recursive close of all states
  # Close child state first
  if not state.subState.isNil:
    state.subState.doClose
  state.close

proc doUpdate(state: State, deltaTime: float32) =
  ## Takes care of correct updating everything
  if state.persistentUpdate or state.subState.isNil:
    state.update(deltaTime)
  if not state.subState.isNil:
    state.subState.update(deltaTime)

proc closeSubState(parentState: State) =
  if not parentState.subState.isNil:
    parentState.subState.doClose

proc openSubState(parentState, subState: State) =
  ## Opens substate (with closing if other is open)
  if not parentState.subState.isNil:
    parentState.subState.doClose
  parentState.subState = subState
  subState.start

proc doRender(state: State) =
  if state.isNil:
    return
  state.rootNode.renderWithAllCameras()
  if not state.subState.isNil:
    doRender(state.subState)

proc doUpdateTransform(state: State) =
  if state.isNil:
    return
  if state.persistentUpdate or state.subState.isNil:
    state.rootNode.updateAllTransforms
  doUpdateTransform(state.subState)

proc rootNode*(state: State): RootNode =
  return state.rootNode

proc game*(state: State): Game =
  return state.game
extends Puzzle
class_name StatePuzzle

## default state array to set up when first setting up the puzzle data
@export var defaultStates: Array[String] = ['default']

## solved state
@export var solvedStates: Array[String] = ['solved']

## map of String -> (T extends PuzzleMechanic). Key is in the format `state1>state2`, where `state1` can be a state string or *. * matches all unmatched start states. Value is the puzzle mechanic to be resolved before the transition in the key can occur
@export var stateTransitionPuzzleMechanics: Dictionary = {}

@export var solvePuzzleMechanic: PuzzleMechanic = null

func _init(
	i_id = '',
	i_prereqRequirements: Array[StoryRequirements] = [],
	i_reward: Reward = null,
	i_defaultStates: Array[String] = ['default'],
	i_solvedStates: Array[String] = ['solved'],
	i_transitionMechanics: Dictionary = {},
	i_solveMechanic: PuzzleMechanic = null,
):
	super(i_id, i_prereqRequirements, i_reward)
	defaultStates = i_defaultStates
	solvedStates = i_solvedStates
	stateTransitionPuzzleMechanics = i_transitionMechanics
	solvePuzzleMechanic = i_solveMechanic

func fix_empty_puzzle_states():
	if not PlayerResources.playerInfo.has_puzzle_states(id):
		PlayerResources.playerInfo.set_puzzle_states(id, defaultStates)

func transition_state(nextState: String, puzzleStateIndex: int, currentState: String = '*'):
	if can_state_transition(nextState, currentState, puzzleStateIndex):
		PlayerResources.playerInfo.set_puzzle_state_at_index(id, puzzleStateIndex, nextState, defaultStates)

func get_transition_mechanic(nextState: String, currentState: String = '*') -> PuzzleMechanic:
	if stateTransitionPuzzleMechanics.has(currentState + '>' + nextState):
		return stateTransitionPuzzleMechanics[currentState + '>' + nextState] as PuzzleMechanic
	if stateTransitionPuzzleMechanics.has('*>' + nextState):
		return stateTransitionPuzzleMechanics['*>' + nextState] as PuzzleMechanic
	return null

func can_state_transition(nextState: String, currentState: String = '*', puzzleStateIndex: int = -1) -> bool:
	var transitionMechanic: PuzzleMechanic = get_transition_mechanic(nextState, currentState)
	if transitionMechanic != null:
		if transitionMechanic.can_solve():
			return true
	else:
		print('StatePuzzle can_state_transition Warning: ', currentState, ' -> ', nextState, ' has no defined transition puzzle mechanic (passed index ', puzzleStateIndex, ')')
		#print(PlayerResources.playerInfo.get_puzzle_states(id))
	if currentState != '*':
		transitionMechanic = get_transition_mechanic(nextState)
		if transitionMechanic != null:
			if transitionMechanic.can_solve():
				return true
			else:
				printerr('StatePuzzle can_state_transition ERROR: * -> ', nextState, ' has no defined transition puzzle mechanic.')
	return false

func can_solve() -> bool:
	if not passes_prereqs():
		return false
	
	var currentStates: Array[String] = PlayerResources.playerInfo.get_puzzle_states(id)
	if len(currentStates) == len(solvedStates):
		for i: int in range(len(currentStates)):
			if currentStates[i] != solvedStates[i]:
				return false
	return solvePuzzleMechanic == null or solvePuzzleMechanic.can_solve()

func solve() -> bool:
	var currentStates: Array[String] = PlayerResources.playerInfo.get_puzzle_states(id)
	if len(currentStates) == len(solvedStates):
		var isSolved: bool = true
		for i: int in range(len(currentStates)):
			if currentStates[i] != solvedStates[i]:
				isSolved = false
				break
		if isSolved and (solvePuzzleMechanic == null or solvePuzzleMechanic.can_solve()):
			var solvedMechanic: bool = solvePuzzleMechanic.solve()
			if solvedMechanic:
				return super.solve()
	return false

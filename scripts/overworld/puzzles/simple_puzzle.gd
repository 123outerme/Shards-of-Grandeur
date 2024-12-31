extends Puzzle
class_name SimplePuzzle

@export var puzzleMechanic: PuzzleMechanic = null

func _init(
	i_id = '',
	i_prereqRequirements: Array[StoryRequirements] = [],
	i_solvedReward = null,
	i_puzzleMechanic: PuzzleMechanic = null,
):
	super(i_id, i_prereqRequirements, i_solvedReward)
	puzzleMechanic = i_puzzleMechanic

func passes_prereqs() -> bool:
	var superPassesPrereqs: bool = super.passes_prereqs()
	return superPassesPrereqs and puzzleMechanic.can_solve()

func is_solved() -> bool:
	return PlayerResources.playerInfo.has_solved_puzzle(id)

func can_solve() -> bool:
	return passes_prereqs()

## executes the solution steps and sets the puzzle as solved to the player
func solve() -> bool:
	var solved: bool = puzzleMechanic.solve()
	if solved:
		super.solve()
	return solved

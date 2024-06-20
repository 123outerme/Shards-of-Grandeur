extends Resource
class_name Puzzle

@export var id: String = ''
## At least one requirement must pass in order for the prereqs to have passed
@export var prereqStoryRequirements: Array[StoryRequirements] = []

func _init(
	i_id = '',
	i_prereqRequirements: Array[StoryRequirements] = [],
):
	id = i_id
	prereqStoryRequirements = i_prereqRequirements

func passes_prereqs() -> bool:
	var passes = len(prereqStoryRequirements) == 0 # if no prereqs, then auto-passes
	for requirement: StoryRequirements in prereqStoryRequirements:
		passes = requirement.is_valid() or passes
	return passes

func is_solved() -> bool:
	return passes_prereqs() and PlayerResources.playerInfo.has_solved_puzzle(id)

## executes the solution steps and sets the puzzle as solved to the player
func solve():
	PlayerResources.playerInfo.set_puzzle_solved(id)

extends Resource
class_name Puzzle

@export var id: String = ''

## At least one requirement must pass in order for the prereqs to have passed
@export var prereqStoryRequirements: Array[StoryRequirements] = []

## the reward to give the player when the puzzle is solved
@export var solvedReward: Reward = null

func _init(
	i_id: String = '',
	i_prereqStoryReqs: Array[StoryRequirements] = [],
	i_reward: Reward = null,
):
	id = i_id
	prereqStoryRequirements = i_prereqStoryReqs
	solvedReward = i_reward

func passes_prereqs() -> bool:
	if is_solved():
		return true
	var passes: bool = len(prereqStoryRequirements) == 0 # if no prereqs, then auto-passes
	for requirement: StoryRequirements in prereqStoryRequirements:
		passes = requirement.is_valid() or passes
	return passes

func is_solved() -> bool:
	return PlayerResources.playerInfo.has_solved_puzzle(id)

func can_solve() -> bool:
	push_error('Puzzle ERROR: can_solve() not overridden for subclass implementation ', get_script().get_global_name())
	return false

func solve() -> bool:
	# TODO give player the reward for solving the puzzle, then potentially handle level ups or full inventory (?)
	#SignalBus.overworld_reward_given.emit(solvedReward)
	PlayerResources.playerInfo.set_puzzle_solved(id)
	PlayerResources.questInventory.auto_update_quests()
	return true

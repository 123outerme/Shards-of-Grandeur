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
	return StoryRequirements.list_is_valid(prereqStoryRequirements)

func is_solved() -> bool:
	return PlayerResources.playerInfo.has_solved_puzzle(id)

func can_solve() -> bool:
	push_error('Puzzle ERROR: can_solve() not overridden for subclass implementation ', get_script().get_global_name())
	return false

func solve() -> bool:
	# give player the reward for solving the puzzle
	SignalBus.give_overworld_rewards(solvedReward, 'Puzzle Rewards')
	PlayerResources.playerInfo.set_puzzle_solved(id)
	var emitted: bool = PlayerResources.questInventory.auto_update_quests()
	if not emitted:
		PlayerResources.story_requirements_updated.emit()
	return true

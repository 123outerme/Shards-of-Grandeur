extends Resource
class_name Puzzle

@export var id: String = ''

## At least one requirement must pass in order for the prereqs to have passed
@export var prereqStoryRequirements: Array[StoryRequirements] = []

## the animated sprites that this puzzle displays with
@export var puzzleSpriteFrames: SpriteFrames = null

## the animation from the SpriteFrames loaded in the AnimatedDecoration to use when the puzzle remains unsolved
@export var unsolvedAnimation: String = 'default'

## the animation from the SpriteFrames loaded in the AnimatedDecoration to use when the puzzle was just solved (transition animation)
@export var solvingAnimation: String = ''

## the animation from the SpriteFrames loaded in the AnimatedDecoration to use when the puzzle remains solved
@export var solvedAnimation: String = ''

## if true, the AnimatedDecoration collision is disabled when the puzzle is in the solved state
@export var disableCollisionOnSolve: bool = false

## if true, the AnimatedDecoration's animation is updated to `solvedAnimation` immediately after finishing the `solvingAnimation`. By setting to false, you must manually update the animation to `solved` later in the solving dialogue sequence
@export var updateAnimOnSolve: bool = true

## the reward to give the player when the puzzle is solved
@export var solvedReward: Reward = null

func _init(
	i_id = '',
	i_prereqRequirements: Array[StoryRequirements] = [],
	i_spriteFrames = null,
	i_unsolvedAnim = '',
	i_solvingAnim = '',
	i_solvedAnim = '',
	i_disableCollisionOnSolve = false,
	i_updateAnimOnSolve: bool = true,
	i_solvedReward = null,
):
	id = i_id
	prereqStoryRequirements = i_prereqRequirements
	puzzleSpriteFrames = i_spriteFrames
	unsolvedAnimation = i_unsolvedAnim
	solvingAnimation = i_solvingAnim
	solvedAnimation = i_solvedAnim
	disableCollisionOnSolve = i_disableCollisionOnSolve
	updateAnimOnSolve = i_updateAnimOnSolve
	solvedReward = i_solvedReward

func passes_prereqs() -> bool:
	if is_solved():
		return true
	var passes: bool = len(prereqStoryRequirements) == 0 # if no prereqs, then auto-passes
	for requirement: StoryRequirements in prereqStoryRequirements:
		passes = requirement.is_valid() or passes
	return passes

func is_solved() -> bool:
	return PlayerResources.playerInfo.has_solved_puzzle(id)

## executes the solution steps and sets the puzzle as solved to the player
func solve():
	# TODO give player the reward for solving the puzzle, then potentially handle level ups or full inventory (?)
	# if level up, delay setting the puzzle solved until after the level up prompt has been dismissed
	PlayerResources.playerInfo.set_puzzle_solved(id)
	PlayerResources.questInventory.auto_update_quests()

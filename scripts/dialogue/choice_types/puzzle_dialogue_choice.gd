extends DialogueChoice
class_name PuzzleDialogueChoice

## the puzzle this dialogue choice operates on
@export var puzzle: Puzzle = null

## the PuzzleState state index to modify (not necessary to be set when using StatePuzzleDecorations, unless `acceptsSolve` is also set)
@export var puzzleStateIndex: int = 0

## If true, selecting this option agrees to complete the puzzle (in case items would be used, etc.)
@export var acceptsSolve: bool = false

## if not empty, sets the state for the Puzzle ID at the `puzzleStateIndex` to this value
@export var setsState: String = ''

## if set and `acceptsSolve` is true, if the choice is selected but the solve cannot happen, play this entry instead
@export var leadsToIfSolveFails: DialogueEntry = null

func _init(
	i_choiceBtn: String = '',
	i_storyRequirements = null,
	i_leadsTo: DialogueEntry = null,
	i_repeatsItem: bool = false,
	i_btnDims: Vector2 = Vector2(80, 40),
	i_turnsInQuest: String = '',
	i_isDeclineChoice: bool = false,
	i_puzzle: Puzzle = null,
	i_puzzleStateIndex: int = 0,
	i_acceptsSolve: bool = false,
	i_setsState: String = '',
	i_leadsToIfSolveFails: DialogueEntry = null,
):
	choiceBtn = i_choiceBtn
	storyRequirements = i_storyRequirements
	leadsTo = i_leadsTo
	repeatsItem = i_repeatsItem
	buttonDims = i_btnDims
	turnsInQuest = i_turnsInQuest
	isDeclineChoice = i_isDeclineChoice
	puzzle = i_puzzle
	puzzleStateIndex = i_puzzleStateIndex
	acceptsSolve = i_acceptsSolve
	setsState = i_setsState
	leadsToIfSolveFails = i_leadsToIfSolveFails

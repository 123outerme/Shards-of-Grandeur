extends Resource
class_name DialogueChoice

## label of the button used for the choice
@export var choiceBtn: String = ''
## requirements for this button to be shown
@export var storyRequirements: StoryRequirements = null
## the dialogue entry this choice leads to
@export var leadsTo: DialogueEntry = null
## the ID of a dialogue already in the dialogue stack to be returned to upon selection (overrides `leadsTo`)
@export var returnsToParentId: String = ''
## the dialogues this choice leads to, picked randomly according to their weights (overrides `leadsTo`)
@export var randomDialogues: Array[WeightedDialogueEntry] = []
## if true, repeats the current dialogue item
@export var repeatsItem: bool = false
## the (minimum) dimensions of the button used for the choice
@export var buttonDims: Vector2 = Vector2(80, 40)
## turns in the quest step, written as "<Quest Name>#<Step Name>"
@export var turnsInQuest: String = ''
## if true, the Decline action will auto-select and choose this choice
@export var isDeclineChoice: bool = false

func _init(
	i_choiceBtn = '',
	i_storyRequirements = null,
	i_leadsTo = null,
	i_returnsToParentId = '',
	i_randomDialogues: Array[WeightedDialogueEntry] = [],
	i_repeatsItem = false,
	i_btnDims = Vector2(80, 40),
	i_turnsInQuest: String = '',
	i_isDeclineChoice = false,
):
	choiceBtn = i_choiceBtn
	storyRequirements = i_storyRequirements
	leadsTo = i_leadsTo
	returnsToParentId = i_returnsToParentId
	randomDialogues = i_randomDialogues
	repeatsItem = i_repeatsItem
	buttonDims = i_btnDims
	turnsInQuest = i_turnsInQuest
	isDeclineChoice = i_isDeclineChoice

func is_valid():
	if storyRequirements == null:
		return true
	return storyRequirements.is_valid()

extends DialogueChoice
class_name NPCDialogueChoice

## if true, opens the NPC's shop
@export var opensShop: bool = false

## if not an empty string, makes the NPCs with the specified follower ID follow the player in the overworld
@export var addsFollowerId: String = ''

## if not an empty string, stops the NPCs with the specified follower ID following the player in the overworld
@export var removesFollowerId: String = ''

func _init(
	i_choiceBtn = '',
	i_storyRequirements = null,
	i_leadsTo = null,
	i_repeatsItem = false,
	i_btnDims = Vector2(80, 40),
	i_turnsInQuest: String = '',
	i_isDeclineChoice = false,
	i_opensShop = false,
):
	choiceBtn = i_choiceBtn
	storyRequirements = i_storyRequirements
	leadsTo = i_leadsTo
	repeatsItem = i_repeatsItem
	buttonDims = i_btnDims
	turnsInQuest = i_turnsInQuest
	isDeclineChoice = i_isDeclineChoice
	opensShop = i_opensShop

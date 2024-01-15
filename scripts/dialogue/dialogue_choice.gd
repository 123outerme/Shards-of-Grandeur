extends Resource
class_name DialogueChoice

@export var choiceBtn: String = ''
@export var leadsTo: DialogueEntry = null
@export var repeatsItem: bool = false
@export var buttonDims: Vector2 = Vector2(80, 40)
@export var turnsInQuest: String = ''
@export var opensShop: bool = false

func _init(
	i_choiceBtn = '',
	i_leadsTo = null,
	i_repeatsItem = false,
	i_btnDims = Vector2(80, 40),
	i_turnsInQuest: String = ''
):
	choiceBtn = i_choiceBtn
	leadsTo = i_leadsTo
	repeatsItem = i_repeatsItem
	buttonDims = i_btnDims
	turnsInQuest = i_turnsInQuest

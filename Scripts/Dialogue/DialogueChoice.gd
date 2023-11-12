extends Resource
class_name DialogueChoice

@export var choiceBtn: String = ''
@export var leadsTo: DialogueEntry = null
@export var buttonDims: Vector2 = Vector2(80, 40)

func _init(
	i_choiceBtn = '',
	i_leadsTo = null,
	i_btnDims = Vector2(80, 40)
):
	choiceBtn = i_choiceBtn
	leadsTo = i_leadsTo
	buttonDims = i_btnDims

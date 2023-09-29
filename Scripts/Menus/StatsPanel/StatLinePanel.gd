extends Panel
class_name StatLinePanel

@export var stats: Stats = null
@export var curHp: int = -1
@export var readOnly: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_statline_panel():
	if stats == null:
		return
	
	if curHp == -1:
		curHp = stats.maxHp

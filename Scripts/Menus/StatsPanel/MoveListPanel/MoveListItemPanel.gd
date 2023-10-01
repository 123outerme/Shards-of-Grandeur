extends Panel

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node("MoveName")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_item_panel():
	if move != null:
		moveName.text = move.moveName
	else:
		moveName.text = '-----'

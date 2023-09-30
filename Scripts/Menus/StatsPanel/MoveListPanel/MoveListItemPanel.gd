extends Panel

@export var move: String = ''

@onready var moveName: RichTextLabel = get_node("MoveName")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_item_panel():
	if move != '':
		moveName.text = move
	else:
		moveName.text = '-----'

extends Panel
class_name MoveListPanel

@export var moves: Array[String] = []
@export var movepool: Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_panel():
	for i in range(4):
		var itemPanel = get_node("VBoxContainer/MoveListItemPanel" + String.num(i + 1))
		if i < len(moves):
			itemPanel.move = moves[i]
		else:
			itemPanel.move = ''
		itemPanel.load_move_list_item_panel()

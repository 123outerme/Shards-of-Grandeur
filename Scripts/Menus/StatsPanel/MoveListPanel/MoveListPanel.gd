extends Panel
class_name MoveListPanel

signal move_details_visiblity_changed(visible: bool)

@export var moves: Array[Move] = []
@export var movepool: Array[Move] = []
@export var readOnly: bool = false

@onready var editMovesButton: Button = get_node("EditMovesButton")
@onready var moveDetailsPanel: MoveDetailsPanel = get_node("MoveDetailsPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_panel():
	for i in range(4):
		var itemPanel = get_node("VBoxContainer/MoveListItemPanel" + String.num(i + 1))
		if i < len(moves):
			itemPanel.move = moves[i]
		else:
			itemPanel.move = null
		itemPanel.load_move_list_item_panel()
	editMovesButton.visible = not readOnly

func _on_move_list_item_details_pressed(move: Move):
	moveDetailsPanel.move = move
	moveDetailsPanel.load_move_details_panel()
	move_details_visiblity_changed.emit(true)

func _on_move_details_panel_back_pressed():
	move_details_visiblity_changed.emit(false)

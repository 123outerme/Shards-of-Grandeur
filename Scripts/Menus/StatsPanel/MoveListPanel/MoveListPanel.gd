extends Panel
class_name MoveListPanel

signal edit_moves
signal move_details_visiblity_changed(visible: bool)
signal edit_moves_replace_clicked(move: Move, index: int)

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
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		if i < len(moves):
			itemPanel.move = moves[i]
		else:
			itemPanel.move = null
		itemPanel.load_move_list_item_panel()
	editMovesButton.visible = not readOnly

func connect_details_pressed(function: Callable):
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		if not itemPanel.details_pressed.is_connected(function):
			itemPanel.details_pressed.connect(function)

func disconnect_details_pressed(function: Callable):
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		if itemPanel.details_pressed.is_connected(function):
			itemPanel.details_pressed.disconnect(function)

func show_move_list_item_details_btns(showing: bool = true):
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		itemPanel.showDetailsButton = showing
		itemPanel.load_move_list_item_panel()

func show_move_list_item_replace_btns(showing: bool = false):
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		itemPanel.editShowReplace = showing
		itemPanel.load_move_list_item_panel()

func get_move_list_item(index: int) -> MoveListItemPanel:
	return get_node("VBoxContainer/MoveListItemPanel" + String.num(index + 1))

func _on_move_list_item_details_pressed(move: Move):
	moveDetailsPanel.move = move
	moveDetailsPanel.load_move_details_panel()
	move_details_visiblity_changed.emit(true)

func _on_move_details_panel_back_pressed():
	move_details_visiblity_changed.emit(false)

func _on_edit_moves_button_pressed():
	edit_moves.emit()

func _on_move_list_item_panel_replace_pressed(move, slot):
	edit_moves_replace_clicked.emit(move, slot)

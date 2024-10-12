extends Panel
class_name MoveListPanel

signal edit_moves
signal move_details_visiblity_changed(visible: bool, previousButton: Button)
signal edit_moves_replace_clicked(move: Move, index: int)
signal edit_moves_reorder_clicked(move: Move, index: int)

@export var moves: Array[Move] = []
@export var movepool: Array[Move] = []
@export var readOnly: bool = false
@export var levelUp: bool = false
@export var level: int = 1
@export var showNewMoveIndicator: bool = false
@export var newMoveIndicator: Texture2D = null

var previousControl: Control = null
var lastMovePanel: MoveListItemPanel = null

@onready var editMovesButton: Button = get_node("EditMovesButton")
@onready var moveDetailsPanel: MoveDetailsPanel = get_node("MoveDetailsPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_panel():
	lastMovePanel = null
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		if lastMovePanel == null:
			itemPanel.set_buttons_top_neighbor('.')
		else:
			itemPanel.connect_move_list_item_panel_top_neighbor(lastMovePanel)
			itemPanel.set_buttons_bottom_neighbor('.')
		if i < len(moves):
			itemPanel.move = moves[i]
			itemPanel.showNewMoveIndicator = levelUp and level == moves[i].requiredLv
			if moves[i] != null:
				lastMovePanel = itemPanel
		else:
			itemPanel.move = null
		itemPanel.load_move_list_item_panel()
	editMovesButton.visible = not readOnly
	if not readOnly and lastMovePanel != null:
		editMovesButton.focus_neighbor_top = editMovesButton.get_path_to(lastMovePanel.detailsButton)
		lastMovePanel.detailsButton.focus_neighbor_bottom = lastMovePanel.detailsButton.get_path_to(editMovesButton)
	editMovesButton.icon = newMoveIndicator if showNewMoveIndicator else null

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
	var lastPanel: MoveListItemPanel = null
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		itemPanel.showDetailsButton = showing
		itemPanel.load_move_list_item_panel()
		if lastPanel != null:
			itemPanel.connect_move_list_item_panel_top_neighbor(lastPanel)
		else:
			itemPanel.set_buttons_top_neighbor('.')
		lastPanel = itemPanel
	lastPanel.set_buttons_bottom_neighbor('.')

func show_move_list_item_replace_btns(showing: bool = false):
	var lastPanel: MoveListItemPanel = null
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		itemPanel.editShowReplace = showing
		itemPanel.load_move_list_item_panel()
		if lastPanel != null:
			itemPanel.connect_move_list_item_panel_top_neighbor(lastPanel)
		else:
			itemPanel.set_buttons_top_neighbor('.')
		lastPanel = itemPanel
	lastPanel.set_buttons_bottom_neighbor('.')

func show_move_list_item_reorder_btns(showing: bool = false):
	var lastPanel: MoveListItemPanel = null
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		itemPanel.editShowReorder = showing
		itemPanel.load_move_list_item_panel()
		if lastPanel != null:
			itemPanel.connect_move_list_item_panel_top_neighbor(lastPanel)
		else:
			itemPanel.set_buttons_top_neighbor('.')
		lastPanel = itemPanel
	lastPanel.set_buttons_bottom_neighbor('.')

func get_move_list_item(index: int) -> MoveListItemPanel:
	return get_node("VBoxContainer/MoveListItemPanel" + String.num(index + 1))

func get_index_of_move(move: Move) -> int:
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		if itemPanel.move == move:
			return i
	return -1

func _on_move_list_item_details_pressed(move: Move):
	moveDetailsPanel.move = move
	moveDetailsPanel.load_move_details_panel()
	move_details_visiblity_changed.emit(true, move)

func _on_move_details_panel_back_pressed():
	move_details_visiblity_changed.emit(false, null)

func _on_edit_moves_button_pressed():
	edit_moves.emit()

func _on_move_list_item_panel_replace_pressed(move, slot):
	'''
	var button: Button = null
	for i in range(4):
		var itemPanel: MoveListItemPanel = get_move_list_item(i)
		if itemPanel.move == move:
			button = itemPanel.detailsButton
	'''
	edit_moves_replace_clicked.emit(move, slot)

func _on_move_list_item_panel_reorder_pressed(move, slot):
	edit_moves_reorder_clicked.emit(move, slot)

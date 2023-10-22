extends Control
class_name EditMovesPanel

signal replace_move(slot: int, newMove: Move)
signal back_pressed

enum MenuState {
	SELECTING_MOVEPOOL_MOVE = 0,
	SELECTING_NEW_SLOT = 1
}

@export var moves: Array[Move] = []
@export var movepool: Array[Move] = []
@export var level: int = 1

var state: MenuState = MenuState.SELECTING_MOVEPOOL_MOVE
var selectedMove: Move = null

@onready var moveListPanel: MoveListPanel = get_node("Panel/MoveListPanel")
@onready var movePoolPanel: MovePoolPanel = get_node("Panel/MovePoolPanel")
@onready var backButton: Button = get_node("Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_edit_moves_panel():
	visible = true
	moveListPanel.moves = moves
	moveListPanel.movepool = movepool
	moveListPanel.readOnly = true
	moveListPanel.load_move_list_panel()
	
	movePoolPanel.moves = moves
	movePoolPanel.movepool = movepool
	movePoolPanel.level = level
	movePoolPanel.load_move_pool_panel()
	
	update_menu_state()
	
func update_menu_state():
	moveListPanel.show_move_list_item_replace_btns(state == MenuState.SELECTING_NEW_SLOT)
	movePoolPanel.show_select_buttons(state == MenuState.SELECTING_MOVEPOOL_MOVE, selectedMove)

func _on_move_pool_panel_details_button_clicked(move: Move):
	moveListPanel.moveDetailsPanel.move = move
	moveListPanel.moveDetailsPanel.load_move_details_panel()
	backButton.disabled = true

func _on_move_list_panel_edit_moves_replace_clicked(move, index):
	replace_move.emit(index, selectedMove)
	state = MenuState.SELECTING_MOVEPOOL_MOVE
	selectedMove = null
	load_edit_moves_panel()

func _on_move_pool_panel_select_button_clicked(move):
	selectedMove = move
	state = MenuState.SELECTING_NEW_SLOT
	update_menu_state()

func _on_move_pool_panel_cancel_button_clicked():
	selectedMove = null
	state = MenuState.SELECTING_MOVEPOOL_MOVE
	selectedMove = null
	update_menu_state()

func _on_move_list_panel_move_details_visiblity_changed(newVis: bool):
	backButton.disabled = newVis
	update_menu_state()

func _on_back_button_pressed():
	back_pressed.emit()
	state = MenuState.SELECTING_MOVEPOOL_MOVE
	selectedMove = null
	update_menu_state()
	visible = false

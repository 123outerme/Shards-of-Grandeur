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
@export var levelUp: bool = false

var state: MenuState = MenuState.SELECTING_MOVEPOOL_MOVE
var selectedMove: Move = null
var previousControl: Control = null
var previousMoveListSlot: int = -1
var previousMovePoolMove: Move = null
var replaceMoveSourceSlot: int = -1
var refocusReorderButton: bool = false

@onready var moveListPanel: MoveListPanel = get_node("Panel/MoveListPanel")
@onready var movePoolPanel: MovePoolPanel = get_node("Panel/MovePoolPanel")
@onready var backButton: Button = get_node("Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline') and not backButton.disabled:
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func initial_focus():
	backButton.grab_focus()

func restore_focus():
	if previousMovePoolMove == null:
		if previousMoveListSlot == -1:
			if replaceMoveSourceSlot == -1:
				initial_focus()
			else:
				var panel = moveListPanel.get_move_list_item(replaceMoveSourceSlot)
				if panel != null:
					panel.replaceButton.grab_focus()
		else:
			if replaceMoveSourceSlot == -1:
				var panel = moveListPanel.get_move_list_item(previousMoveListSlot)
				if panel != null:
					if refocusReorderButton:
						refocusReorderButton = false
						panel.reorderButton.grab_focus()
					else:
						panel.detailsButton.grab_focus()
			else:
				var panel = moveListPanel.get_move_list_item(replaceMoveSourceSlot)
				replaceMoveSourceSlot = -1
				if panel != null:
					panel.replaceButton.grab_focus()
			previousMoveListSlot = -1
	else:
		var panel = movePoolPanel.get_move_list_item(previousMovePoolMove)
		if panel != null:
			panel.detailsButton.grab_focus()
		previousMovePoolMove = null

func load_edit_moves_panel(rebuild: bool = true, changeFocus: bool = true):
	visible = true
	moveListPanel.moves = moves
	moveListPanel.movepool = movepool
	moveListPanel.readOnly = true
	moveListPanel.level = level
	moveListPanel.levelUp = levelUp
	moveListPanel.load_move_list_panel()
	movePoolPanel.moves = moves
	movePoolPanel.movepool = movepool
	movePoolPanel.level = level
	movePoolPanel.levelUp = levelUp
	movePoolPanel.load_move_pool_panel(rebuild)
	
	update_menu_state(changeFocus)
	if changeFocus:
		restore_focus()
	
func update_menu_state(grabFocus: bool = true):
	moveListPanel.show_move_list_item_reorder_btns(state == MenuState.SELECTING_MOVEPOOL_MOVE)
	moveListPanel.show_move_list_item_replace_btns(state == MenuState.SELECTING_NEW_SLOT)
	movePoolPanel.show_select_buttons(state == MenuState.SELECTING_MOVEPOOL_MOVE, selectedMove, grabFocus)
	
	if state == MenuState.SELECTING_NEW_SLOT:
		backButton.focus_neighbor_top = backButton.get_path_to(moveListPanel.get_move_list_item(3).replaceButton)
	elif moveListPanel.lastMovePanel != null:
		backButton.focus_neighbor_top = backButton.get_path_to(moveListPanel.lastMovePanel.reorderButton)
	
	if moveListPanel.lastMovePanel != null:
		moveListPanel.lastMovePanel.detailsButton.focus_neighbor_bottom = moveListPanel.lastMovePanel.detailsButton.get_path_to(backButton)
		if state == MenuState.SELECTING_MOVEPOOL_MOVE:
			moveListPanel.lastMovePanel.reorderButton.focus_neighbor_bottom = moveListPanel.lastMovePanel.reorderButton.get_path_to(backButton)
		else:
			moveListPanel.get_move_list_item(3).focus_neighbor_bottom = moveListPanel.lastMovePanel.replaceButton.get_path_to(backButton)
	
	if movePoolPanel.firstMovePanel != null:
		backButton.focus_neighbor_bottom = backButton.get_path_to(movePoolPanel.firstMovePanel.detailsButton)
		movePoolPanel.firstMovePanel.detailsButton.focus_neighbor_top = movePoolPanel.firstMovePanel.detailsButton.get_path_to(backButton)
	else:
		backButton.focus_neighbor_bottom = backButton.get_path_to(backButton) # get path to self to prevent losing focus
	backButton.focus_neighbor_left = backButton.get_path_to(backButton)
	backButton.focus_neighbor_right = backButton.get_path_to(backButton)

func reset_menu_state():
	state = MenuState.SELECTING_MOVEPOOL_MOVE
	selectedMove = null
	previousMoveListSlot = -1
	previousMovePoolMove = null
	replaceMoveSourceSlot = -1
	moveListPanel.moveDetailsPanel.visible = false
	update_menu_state()

func _on_move_pool_panel_details_button_clicked(move: Move):
	moveListPanel.moveDetailsPanel.move = move
	previousMovePoolMove = move
	moveListPanel.moveDetailsPanel.load_move_details_panel()
	backButton.disabled = true

func _on_move_list_panel_edit_moves_reorder_clicked(move, index):
	replaceMoveSourceSlot = index
	selectedMove = move
	state = MenuState.SELECTING_NEW_SLOT
	load_edit_moves_panel(false)
	restore_focus()

func _on_move_list_panel_edit_moves_replace_clicked(move, index):
	previousMoveListSlot = index
	if replaceMoveSourceSlot != -1:
		replace_move.emit(replaceMoveSourceSlot, move)
	replace_move.emit(index, selectedMove)
	state = MenuState.SELECTING_MOVEPOOL_MOVE
	selectedMove = null
	replaceMoveSourceSlot = -1
	refocusReorderButton = true
	load_edit_moves_panel(true, false)
	restore_focus()

func _on_move_pool_panel_select_button_clicked(move: Move):
	selectedMove = move
	previousMovePoolMove = move
	state = MenuState.SELECTING_NEW_SLOT
	update_menu_state()
	restore_focus()

func _on_move_pool_panel_cancel_button_clicked():
	previousMovePoolMove = selectedMove
	selectedMove = null
	state = MenuState.SELECTING_MOVEPOOL_MOVE
	selectedMove = null
	update_menu_state()
	restore_focus()

func _on_move_list_panel_move_details_visiblity_changed(newVis: bool, move: Move):
	backButton.disabled = newVis
	update_menu_state(false)
	if newVis and previousMovePoolMove == null:
		previousMoveListSlot = moveListPanel.get_index_of_move(move)
	elif not newVis:
		restore_focus()

func _on_back_button_pressed():
	reset_menu_state()
	visible = false
	back_pressed.emit()

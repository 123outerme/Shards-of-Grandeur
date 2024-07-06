extends Panel
class_name MovePoolPanel

signal details_button_clicked(move: Move)
signal select_button_clicked(move: Move)
signal learn_button_clicked(move: Move)
signal cancel_button_clicked

const moveListItemPanel = preload("res://prefabs/ui/stats/move_list_item_panel.tscn")

@export var moves: Array[Move] = []
@export var movepool: Array[Move] = []
@export var level: int = 1
@export var hideMovesInMoveList: bool = false
@export var levelUp: bool = false

var firstMovePanel: MoveListItemPanel = null

@onready var vboxContainer: VBoxContainer = get_node("ScrollContainer/VBoxContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_move_pool_panel(rebuild: bool = true):
	if rebuild:
		for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
			panel.queue_free()
	
		firstMovePanel = null
		var lastMovePanel: MoveListItemPanel = null
		var sortedMovepool: Array[Move] = movepool.duplicate()
		sortedMovepool.sort_custom(_sort_by_level_desc)
		for move in sortedMovepool:
			if move.requiredLv <= level and \
					not (hideMovesInMoveList and (move in moves)):
				var instantiatedPanel: MoveListItemPanel = moveListItemPanel.instantiate()
				instantiatedPanel.move = move
				instantiatedPanel.showNewMoveIndicator = levelUp and move.requiredLv == level
				instantiatedPanel.details_pressed.connect(_on_details_button_clicked)
				instantiatedPanel.select_pressed.connect(_on_select_button_clicked)
				instantiatedPanel.learn_pressed.connect(_on_learn_button_clicked)
				instantiatedPanel.cancel_pressed.connect(_on_cancel_button_clicked)
				instantiatedPanel.add_to_group('MovePoolPanelMove')
				vboxContainer.add_child(instantiatedPanel)
				instantiatedPanel.call_deferred('load_move_list_item_panel')
				if firstMovePanel == null:
					firstMovePanel = instantiatedPanel
				lastMovePanel = instantiatedPanel
		if lastMovePanel != null:
			lastMovePanel.detailsButton.focus_neighbor_bottom = NodePath('.')
			lastMovePanel.cancelButton.focus_neighbor_bottom = NodePath('.')
			lastMovePanel.reorderButton.focus_neighbor_bottom = NodePath('.')
			lastMovePanel.replaceButton.focus_neighbor_bottom = NodePath('.')
			lastMovePanel.selectButton.focus_neighbor_bottom = NodePath('.')
	else:
		var panels: Array[Node] = get_tree().get_nodes_in_group('MovePoolPanelMove')
		for idx in range(len(panels)):
			var panel: MoveListItemPanel = panels[idx] as MoveListItemPanel
			panel.move = movepool[idx]
			panel.load_move_list_item_panel()

func show_select_buttons(showing: bool = true, exception: Move = null, grabFocus = true):
	var hasFocused = not grabFocus # take focus if grabFocus is true, otherwise pretend like it's already been taken
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var movePanel: MoveListItemPanel = panel as MoveListItemPanel
		movePanel.movepoolSelect = showing and exception != movePanel.move and not (movePanel.move in moves)
		movePanel.movepoolCancel = exception == movePanel.move
		movePanel.load_move_list_item_panel()
		if not hasFocused and movePanel.selectButton.visible:
			movePanel.selectButton.grab_focus()
			hasFocused = true
		
func show_learn_buttons(showing: bool = true):
	var hasFocused = false
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var movePanel: MoveListItemPanel = panel as MoveListItemPanel
		movePanel.movepoolLearn = showing and not (movePanel.move in PlayerResources.playerInfo.combatant.stats.movepool.pool)
		movePanel.load_move_list_item_panel()
		if not hasFocused and movePanel.selectButton.visible:
			movePanel.selectButton.grab_focus()
			hasFocused = true

func get_move_list_item(move: Move) -> MoveListItemPanel:
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var movePanel: MoveListItemPanel = panel as MoveListItemPanel
		if movePanel.move == move:
			return movePanel
	return null

func connect_bottom_panel_buttons_focus_bottom_to(control: Control):
	var panels: Array[Node] = get_tree().get_nodes_in_group('MovePoolPanelMove')
	var bottomPanel: MoveListItemPanel = panels[len(panels) - 1] as MoveListItemPanel
	
	bottomPanel.detailsButton.focus_neighbor_bottom = bottomPanel.detailsButton.get_path_to(control)
	bottomPanel.replaceButton.focus_neighbor_bottom = bottomPanel.replaceButton.get_path_to(control)
	bottomPanel.learnButton.focus_neighbor_bottom = bottomPanel.learnButton.get_path_to(control)
	bottomPanel.cancelButton.focus_neighbor_bottom = bottomPanel.cancelButton.get_path_to(control)
	bottomPanel.reorderButton.focus_neighbor_bottom = bottomPanel.reorderButton.get_path_to(control)
	bottomPanel.selectButton.focus_neighbor_bottom = bottomPanel.selectButton.get_path_to(control)
	
	control.focus_neighbor_top = control.get_path_to(bottomPanel.detailsButton)

func focus_move_details(move: Move) -> bool:
	var focusGrabbed: bool = false
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var movePanel: MoveListItemPanel = panel as MoveListItemPanel
		if movePanel.move == move:
			movePanel.detailsButton.grab_focus()
			focusGrabbed = true
			break
	return focusGrabbed

func get_learnable_move_count() -> int:
	var count: int = 0
	for move in movepool:
		if not (move in PlayerResources.playerInfo.combatant.stats.movepool.pool) and \
				move.requiredLv <= PlayerResources.playerInfo.combatant.stats.level:
			count += 1
	return count

func _on_details_button_clicked(move: Move):
	details_button_clicked.emit(move)

func _on_select_button_clicked(move: Move):
	select_button_clicked.emit(move)

func _on_learn_button_clicked(move: Move):
	learn_button_clicked.emit(move)

func _on_cancel_button_clicked():
	cancel_button_clicked.emit()

func _sort_by_level_desc(a: Move, b: Move) -> bool:
	if a.requiredLv > b.requiredLv:
		return true
	return false

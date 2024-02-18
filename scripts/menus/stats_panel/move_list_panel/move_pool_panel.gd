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

var firstMovePanel: MoveListItemPanel = null

@onready var vboxContainer: VBoxContainer = get_node("ScrollContainer/VBoxContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_move_pool_panel():
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		panel.queue_free()
	
	firstMovePanel = null
	
	for move in movepool:
		if move.requiredLv <= level and \
				not (hideMovesInMoveList and (move in moves)):
			var instantiatedPanel: MoveListItemPanel = moveListItemPanel.instantiate()
			instantiatedPanel.move = move
			instantiatedPanel.details_pressed.connect(_on_details_button_clicked)
			instantiatedPanel.select_pressed.connect(_on_select_button_clicked)
			instantiatedPanel.learn_pressed.connect(_on_learn_button_clicked)
			instantiatedPanel.cancel_pressed.connect(_on_cancel_button_clicked)
			instantiatedPanel.add_to_group('MovePoolPanelMove')
			vboxContainer.add_child(instantiatedPanel)
			instantiatedPanel.call_deferred('load_move_list_item_panel')
			if firstMovePanel == null:
				firstMovePanel = instantiatedPanel

func show_select_buttons(showing: bool = true, exception: Move = null):
	var hasFocused = false
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

func focus_move_details(move: Move) -> bool:
	var focusGrabbed: bool = false
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var movePanel: MoveListItemPanel = panel as MoveListItemPanel
		if movePanel.move == move:
			movePanel.detailsButton.grab_focus()
			focusGrabbed = true
			break
	return focusGrabbed

func _on_details_button_clicked(move: Move):
	details_button_clicked.emit(move)

func _on_select_button_clicked(move: Move):
	select_button_clicked.emit(move)

func _on_learn_button_clicked(move: Move):
	learn_button_clicked.emit(move)

func _on_cancel_button_clicked():
	cancel_button_clicked.emit()

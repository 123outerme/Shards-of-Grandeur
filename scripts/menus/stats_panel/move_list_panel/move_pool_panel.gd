extends Panel
class_name MovePoolPanel

signal details_button_clicked(move: Move)
signal select_button_clicked(move: Move)
signal learn_button_clicked(move: Move)
signal cancel_button_clicked

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
	var moveListItemPanel = preload("res://prefabs/ui/stats/move_list_item_panel.tscn")
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
		var moveListItemPanel: MoveListItemPanel = panel as MoveListItemPanel
		moveListItemPanel.movepoolSelect = showing and exception != moveListItemPanel.move and not (moveListItemPanel.move in moves)
		moveListItemPanel.movepoolCancel = exception == moveListItemPanel.move
		moveListItemPanel.load_move_list_item_panel()
		if not hasFocused and moveListItemPanel.selectButton.visible:
			moveListItemPanel.selectButton.grab_focus()
			hasFocused = true
		
func show_learn_buttons(showing: bool = true):
	var hasFocused = false
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var moveListItemPanel: MoveListItemPanel = panel as MoveListItemPanel
		moveListItemPanel.movepoolLearn = showing and not (moveListItemPanel.move in PlayerResources.playerInfo.stats.movepool)
		moveListItemPanel.load_move_list_item_panel()
		if not hasFocused and moveListItemPanel.selectButton.visible:
			moveListItemPanel.selectButton.grab_focus()
			hasFocused = true

func get_move_list_item(move: Move) -> MoveListItemPanel:
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var moveListItemPanel: MoveListItemPanel = panel as MoveListItemPanel
		if moveListItemPanel.move == move:
			return moveListItemPanel
	return null

func focus_move_details(move: Move) -> bool:
	var focusGrabbed: bool = false
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var moveListItemPanel: MoveListItemPanel = panel as MoveListItemPanel
		if moveListItemPanel.move == move:
			moveListItemPanel.detailsButton.grab_focus()
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

extends Panel
class_name MovePoolPanel

signal details_button_clicked(move: Move)
signal select_button_clicked(move: Move)
signal learn_button_clicked(move: Move)
signal cancel_button_clicked

@export var moves: Array[Move] = []
@export var movepool: Array[Move] = []
@export var level: int = 1

@onready var vboxContainer: VBoxContainer = get_node("ScrollContainer/VBoxContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_move_pool_panel():
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		panel.queue_free()
	
	var moveListItemPanel = preload("res://Prefabs/UI/Stats/MoveListItemPanel.tscn")
	for move in movepool:
		if move.requiredLv <= level:
			var instantiatedPanel: MoveListItemPanel = moveListItemPanel.instantiate()
			instantiatedPanel.move = move
			instantiatedPanel.details_pressed.connect(_on_details_button_clicked)
			instantiatedPanel.select_pressed.connect(_on_select_button_clicked)
			instantiatedPanel.learn_pressed.connect(_on_learn_button_clicked)
			instantiatedPanel.cancel_pressed.connect(_on_cancel_button_clicked)
			instantiatedPanel.add_to_group('MovePoolPanelMove')
			vboxContainer.add_child(instantiatedPanel)
			instantiatedPanel.call_deferred('load_move_list_item_panel')

func show_select_buttons(showing: bool = true, exception: Move = null):
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var moveListItemPanel: MoveListItemPanel = panel as MoveListItemPanel
		moveListItemPanel.movepoolSelect = showing and exception != moveListItemPanel.move and not (moveListItemPanel.move in moves)
		moveListItemPanel.movepoolCancel = exception == moveListItemPanel.move
		moveListItemPanel.load_move_list_item_panel()
		
func show_learn_buttons(showing: bool = true):
	for panel in get_tree().get_nodes_in_group('MovePoolPanelMove'):
		var moveListItemPanel: MoveListItemPanel = panel as MoveListItemPanel
		moveListItemPanel.movepoolLearn = showing
		moveListItemPanel.load_move_list_item_panel()

func _on_details_button_clicked(move: Move):
	details_button_clicked.emit(move)

func _on_select_button_clicked(move: Move):
	select_button_clicked.emit(move)

func _on_learn_button_clicked(move: Move):
	learn_button_clicked.emit(move)

func _on_cancel_button_clicked():
	cancel_button_clicked.emit()

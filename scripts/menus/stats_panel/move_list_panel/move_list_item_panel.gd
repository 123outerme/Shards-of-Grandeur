extends Panel
class_name MoveListItemPanel

signal details_pressed(move: Move)
signal replace_pressed(move: Move, slot: int)
signal reorder_pressed(move: Move, slot: int)
signal select_pressed(move: Move)
signal learn_pressed(move: Move)
signal cancel_pressed

@export var move: Move = null
@export var showDetailsButton: bool = true
@export var editShowReplace: bool = false
@export var editShowReorder: bool = false
@export var movepoolSelect: bool = false
@export var movepoolLearn: bool = false
@export var movepoolCancel: bool = false
@export var moveSlot: int = -1
@export var showNewMoveIndicator: bool = false

@onready var moveName: RichTextLabel = get_node("CenterMoveName/MoveName")
@onready var moveLevel: RichTextLabel = get_node("CenterMoveName/MoveLevel")
@onready var damageType: RichTextLabel = get_node("CenterDetails/DamageType")
@onready var newMoveIndicator: Control = get_node('CenterNewMove/MoveIndicatorControl')
@onready var detailsButton: Button = get_node("DetailsButton")
@onready var reorderButton: Button = get_node("ReorderButton")
@onready var replaceButton: Button = get_node("ReplaceButton")
@onready var selectButton: Button = get_node("SelectButton")
@onready var learnButton: Button = get_node("LearnButton")
@onready var cancelButton: Button = get_node("CancelButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_move_list_item_panel():
	if move != null:
		moveName.text = move.moveName
		moveLevel.text = ' Lv ' + String.num_int64(move.requiredLv)
		
		if move.element == Move.Element.NONE:
			damageType.text = ''
		else:
			damageType.text = Move.element_to_string(move.element) + '\n'
		
		damageType.text += Move.dmg_category_to_string(move.category)
		newMoveIndicator.visible = showNewMoveIndicator
		detailsButton.visible = showDetailsButton
		detailsButton.focus_neighbor_left = detailsButton.get_path_to(detailsButton)
		
		replaceButton.visible = editShowReplace
		if replaceButton.visible:
			detailsButton.focus_neighbor_left = detailsButton.get_path_to(replaceButton)
		
		reorderButton.visible = editShowReorder
		if reorderButton.visible:
			detailsButton.focus_neighbor_left = detailsButton.get_path_to(reorderButton)
					
		selectButton.visible = movepoolSelect
		if selectButton.visible:
			detailsButton.focus_neighbor_left = detailsButton.get_path_to(selectButton)
		
		learnButton.visible = movepoolLearn
		if learnButton.visible:
			detailsButton.focus_neighbor_left = detailsButton.get_path_to(learnButton)
		
		cancelButton.visible = movepoolCancel
		if cancelButton.visible:
			detailsButton.focus_neighbor_left = detailsButton.get_path_to(cancelButton)
	else:
		moveName.text = '-----'
		moveLevel.text = ''
		damageType.text = ''
		detailsButton.visible = false
		replaceButton.visible = editShowReplace
		reorderButton.visible = false
		selectButton.visible = false
		learnButton.visible = false
		cancelButton.visible = false
		newMoveIndicator.visible = false

func set_buttons_bottom_neighbor(path: String) -> void:
	detailsButton.focus_neighbor_bottom = path
	replaceButton.focus_neighbor_bottom = path
	reorderButton.focus_neighbor_bottom = path
	selectButton.focus_neighbor_bottom = path
	learnButton.focus_neighbor_bottom = path
	cancelButton.focus_neighbor_bottom = path

func set_buttons_top_neighbor(path: String) -> void:
	detailsButton.focus_neighbor_top = path
	replaceButton.focus_neighbor_top = path
	reorderButton.focus_neighbor_top = path
	selectButton.focus_neighbor_top = path
	learnButton.focus_neighbor_top = path
	cancelButton.focus_neighbor_top = path

func connect_move_list_item_panel_top_neighbor(other: MoveListItemPanel) -> void:
	detailsButton.focus_neighbor_top = detailsButton.get_path_to(other.detailsButton)
	other.detailsButton.focus_neighbor_bottom = other.detailsButton.get_path_to(detailsButton)
	
	if other.replaceButton.visible:
		if replaceButton.visible:
			replaceButton.focus_neighbor_top = replaceButton.get_path_to(other.replaceButton)
			other.replaceButton.focus_neighbor_bottom = other.replaceButton.get_path_to(replaceButton)
		else:
			other.replaceButton.focus_neighbor_bottom = other.replaceButton.get_path_to(detailsButton)
	else:
		replaceButton.focus_neighbor_top = replaceButton.get_path_to(other.detailsButton)
	
	if other.reorderButton.visible:
		if reorderButton.visible:
			reorderButton.focus_neighbor_top = reorderButton.get_path_to(other.reorderButton)
			other.reorderButton.focus_neighbor_bottom = other.reorderButton.get_path_to(reorderButton)
		else:
			other.reorderButton.focus_neighbor_bottom = other.reorderButton.get_path_to(detailsButton)
	else: 
		reorderButton.focus_neighbor_top = reorderButton.get_path_to(other.detailsButton)
		
	if other.selectButton.visible:
		if selectButton.visible:
			selectButton.focus_neighbor_top = selectButton.get_path_to(other.selectButton)
			other.selectButton.focus_neighbor_bottom = other.selectButton.get_path_to(selectButton)
		else:
			other.selectButton.focus_neighbor_bottom = other.selectButton.get_path_to(detailsButton)
	else:
		selectButton.focus_neighbor_top = selectButton.get_path_to(other.detailsButton)
	
	if other.learnButton.visible:
		if learnButton.visible:
			learnButton.focus_neighbor_top = learnButton.get_path_to(other.learnButton)
			other.learnButton.focus_neighbor_bottom = other.learnButton.get_path_to(learnButton)
		else:
			other.learnButton.focus_neighbor_bottom = other.learnButton.get_path_to(detailsButton)
	else:
		learnButton.focus_neighbor_top = learnButton.get_path_to(other.detailsButton)
	
	if other.cancelButton.visible:
		if cancelButton.visible:
			cancelButton.focus_neighbor_top = cancelButton.get_path_to(other.cancelButton)
			other.cancelButton.focus_neighbor_bottom = other.cancelButton.get_path_to(cancelButton)
		else:
			other.cancelButton.focus_neighbor_bottom = other.cancelButton.get_path_to(detailsButton)
	else:
		cancelButton.focus_neighbor_top = cancelButton.get_path_to(other.detailsButton)

func _on_details_button_pressed():
	details_pressed.emit(move)

func _on_replace_button_pressed():
	replace_pressed.emit(move, moveSlot)

func _on_reorder_button_pressed():
	reorder_pressed.emit(move, moveSlot)
	
func _on_select_button_pressed():
	select_pressed.emit(move)

func _on_learn_button_pressed():
	learn_pressed.emit(move)

func _on_cancel_button_pressed():
	cancel_pressed.emit()

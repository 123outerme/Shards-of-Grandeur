extends Control
class_name MoveDetailsPanel

signal back_pressed

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node('Panel/MoveName')
@onready var requiredLv: RichTextLabel = get_node("Panel/RequiredLv")
@onready var moveRole: RichTextLabel = get_node("Panel/MoveRole")
@onready var movePower: RichTextLabel = get_node("Panel/MovePower")
@onready var moveCategory: RichTextLabel = get_node("Panel/DamageCategory")
@onready var moveTargets: RichTextLabel = get_node("Panel/MoveTargets")
@onready var moveStatChanges: RichTextLabel = get_node("Panel/MoveStatChanges")
@onready var moveStatusEffect: RichTextLabel = get_node("Panel/MoveStatusEffect")
@onready var moveStatusChance: RichTextLabel = get_node("Panel/MoveStatusChance")
@onready var moveDescription: RichTextLabel = get_node("Panel/MoveDescription")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_move_details_panel():
	if move == null:
		visible = false
		return
	
	visible = true
	moveName.text = '[center]' + move.moveName + '[/center]'
	requiredLv.text = 'Required Level: ' + str(move.requiredLv)
	moveRole.text = '[center]' + Move.role_to_string(move.role) + '[/center]'
	
func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

extends Control
class_name MoveDetailsPanel

signal back_pressed

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node('Panel/MoveName')
@onready var damageCategory: RichTextLabel = get_node("Panel/DamageCategory")
@onready var requiredLv: RichTextLabel = get_node("Panel/RequiredLv")
@onready var moveDescription: RichTextLabel = get_node("Panel/MoveDescription")
@onready var backButton: Button = get_node("Panel/BackButton")

@onready var chargeEffectDetails: MoveEffectDetailsPanel = get_node('Panel/ChargeEffectDetailsPanel')
@onready var surgeEffectDetails: MoveEffectDetailsPanel = get_node('Panel/SurgeEffectDetailsPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func load_move_details_panel():
	if move == null:
		visible = false
		return

	visible = true
	moveName.text = '[center]' + move.moveName + '[/center]'
	damageCategory.text = Move.dmg_category_to_string(move.category)
	requiredLv.text = '[right]Required Level: ' + str(move.requiredLv) + '[/right]'
	moveDescription.text = move.description
	backButton.grab_focus()
	
	chargeEffectDetails.moveEffect = move.chargeEffect
	chargeEffectDetails.load_move_effect_details_panel()
	surgeEffectDetails.moveEffect = move.surgeEffect
	surgeEffectDetails.load_move_effect_details_panel()
	
func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

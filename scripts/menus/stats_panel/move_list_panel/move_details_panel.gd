extends Control
class_name MoveDetailsPanel

signal back_pressed

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node('Panel/MoveName')
@onready var damageCategory: RichTextLabel = get_node("Panel/DamageCategory")
@onready var requiredLv: RichTextLabel = get_node("Panel/RequiredLv")
@onready var moveDescription: RichTextLabel = get_node("Panel/MoveDescription")
@onready var backButton: Button = get_node("Panel/BackButton")

@onready var chargeEffectDetails: MoveEffectDetailsPanel = get_node('Panel/HBoxContainer/ChargeEffectDetailsPanel')
@onready var surgeEffectDetails: MoveEffectDetailsPanel = get_node('Panel/HBoxContainer/SurgeEffectDetailsPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func initial_focus():
	backButton.grab_focus()

func load_move_details_panel():
	if move == null:
		visible = false
		return

	visible = true
	moveName.text = '[center]' + move.moveName + '[/center]'
	if move.element == Move.Element.NONE:
		damageCategory.text = ''
	else:
		damageCategory.text = Move.element_to_string(move.element) + '/'
	
	damageCategory.text += Move.dmg_category_to_string(move.category)

	requiredLv.text = '[right]Required Level: ' + str(move.requiredLv) + '[/right]'
	moveDescription.text = move.description
	initial_focus()
	
	chargeEffectDetails.moveEffect = move.chargeEffect
	chargeEffectDetails.load_move_effect_details_panel()
	surgeEffectDetails.moveEffect = move.surgeEffect
	surgeEffectDetails.load_move_effect_details_panel()
	if not surgeEffectDetails.visible:
		chargeEffectDetails.tooltipPanel.position = Vector2(-371, -247)
	else:
		chargeEffectDetails.tooltipPanel.position = Vector2(-96, -247)
	
	connect_help_buttons()

func connect_help_buttons():
	backButton.focus_neighbor_top = '.'
	backButton.focus_neighbor_left = '.'
	backButton.focus_neighbor_right = '.'
	
	if surgeEffectDetails.visible and move.surgeEffect.statusEffect != null:
		backButton.focus_neighbor_top = backButton.get_path_to(surgeEffectDetails.statusHelpButton)
		surgeEffectDetails.statusHelpButton.focus_neighbor_bottom = surgeEffectDetails.statusHelpButton.get_path_to(backButton)
		backButton.focus_neighbor_right = backButton.get_path_to(surgeEffectDetails.statusHelpButton)
		surgeEffectDetails.statusHelpButton.focus_neighbor_left = surgeEffectDetails.statusHelpButton.get_path_to(backButton)
	
	if move.chargeEffect.statusEffect != null:
		backButton.focus_neighbor_top = backButton.get_path_to(chargeEffectDetails.statusHelpButton)
		chargeEffectDetails.statusHelpButton.focus_neighbor_bottom = chargeEffectDetails.statusHelpButton.get_path_to(backButton)
		if surgeEffectDetails.visible:
			backButton.focus_neighbor_left = backButton.get_path_to(chargeEffectDetails.statusHelpButton)
			if move.surgeEffect.statusEffect != null:
				chargeEffectDetails.statusHelpButton.focus_neighbor_right = chargeEffectDetails.statusHelpButton.get_path_to(surgeEffectDetails.statusHelpButton)
				surgeEffectDetails.statusHelpButton.focus_neighbor_left = surgeEffectDetails.statusHelpButton.get_path_to(chargeEffectDetails.statusHelpButton)
			else:
				chargeEffectDetails.statusHelpButton.focus_neighbor_right = chargeEffectDetails.statusHelpButton.get_path_to(backButton)
			

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

extends Control
class_name MoveDetailsPanel

signal back_pressed

@export var move: Move = null

@onready var moveName: RichTextLabel = get_node('Panel/MoveName')
@onready var movePower: RichTextLabel = get_node("Panel/MovePower")
@onready var damageCategory: RichTextLabel = get_node("Panel/DamageCategory")
@onready var moveTargets: RichTextLabel = get_node("Panel/MoveTargets")
@onready var requiredLv: RichTextLabel = get_node("Panel/RequiredLv")
@onready var moveRole: RichTextLabel = get_node("Panel/MoveRole")
@onready var moveStatChanges: RichTextLabel = get_node("Panel/MoveStatChanges")
@onready var moveStatusEffect: RichTextLabel = get_node("Panel/MoveStatusEffect")
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
	movePower.text = str(move.power) + ' Power'
	damageCategory.text = Move.dmg_category_to_string(move.category)
	moveTargets.text = '[center]Targets ' + BattleCommand.targets_to_string(move.targets) + '[/center]'
	requiredLv.text = '[right]Required Level: ' + str(move.requiredLv) + '[/right]'
	moveRole.text = '[right]' + Move.role_to_string(move.role) + '[/right]'
	moveStatChanges.text = ''
	var multipliers: Array[StatMultiplierText] = move.statChanges.get_multipliers_text()
	for idx in range(len(multipliers)):
		moveStatChanges.text += multipliers[idx].print_multiplier()
		if idx < len(multipliers) - 1:
			if len(multipliers) > 2:
				moveStatChanges.text += ','
			if idx == len(multipliers) - 2:
				moveStatChanges.text += ' and'
			moveStatChanges.text += ' '
	if move.statusEffect != null:
		moveStatusEffect.text = '[center]Applies ' + move.statusEffect.status_effect_to_string() + ' (' + String.num(move.statusChance * 100.0, 0) + '% Chance)[/center]'
	else:
		moveStatusEffect.text = ''
	moveDescription.text = move.description
	
func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

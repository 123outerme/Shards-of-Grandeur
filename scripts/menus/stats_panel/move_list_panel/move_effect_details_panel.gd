extends Panel
class_name MoveEffectDetailsPanel

@export var moveEffect: MoveEffect = null
@export var isSurgeEffect: bool = false

@onready var detailsTitleLabel: RichTextLabel = get_node('DetailsTitle')
@onready var moveTargets: RichTextLabel = get_node("MoveTargets")
@onready var movePower: RichTextLabel = get_node("MovePower")
@onready var moveRole: RichTextLabel = get_node("MoveRole")
@onready var userStatChanges: RichTextLabel = get_node("VBoxContainer/UserStatChanges")
@onready var targetStatChanges: RichTextLabel = get_node("VBoxContainer/TargetStatChanges")
@onready var moveStatusEffect: RichTextLabel = get_node("VBoxContainer/MoveStatusEffect")
@onready var surgeChangesDescription: RichTextLabel = get_node('VBoxContainer/SurgeChangesDescription')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_move_effect_details_panel():
	if moveEffect == null:
		visible = false
		return
	if Combatant.useSurgeReqs == null or Combatant.useSurgeReqs.is_valid():
		detailsTitleLabel.text = '[center]' + ('Surge Effect' if isSurgeEffect else 'Charge Effect') + ' ('
		if moveEffect.orbChange > 0:
			detailsTitleLabel.text += '+'
		detailsTitleLabel.text += String.num(moveEffect.orbChange) + ' Orb'
		if abs(moveEffect.orbChange) > 1 or moveEffect.orbChange == 0:
			detailsTitleLabel.text += 's'
		if moveEffect.orbChange < 0:
			detailsTitleLabel.text += ' Min.'
		detailsTitleLabel.text += ')[/center]'
	else:
		if isSurgeEffect:
			visible = false
			return
		else:
			detailsTitleLabel.text = '[center]Move Effect[/center]'
	
	if moveEffect.power >= 0:
		movePower.text = str(moveEffect.power) + ' Power'
	else:
		movePower.text = str(moveEffect.power * -1) + ' Heal Power'
	moveTargets.text = '[center]Targets ' + BattleCommand.targets_to_string(moveEffect.targets) + '[/center]'
	moveRole.text = '[right]' + MoveEffect.role_to_string(moveEffect.role) + '[/right]'

	if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
		var multipliers = moveEffect.selfStatChanges.get_multipliers_text()
		userStatChanges.text = '[center]User boosts self:\n' + StatMultiplierText.multiplier_text_list_to_string(multipliers) + '\n [/center]'
		userStatChanges.visible = true
	else:
		userStatChanges.visible = false
		
	if moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes():
		var multipliers = moveEffect.targetStatChanges.get_multipliers_text()
		targetStatChanges.text = '[center]User boosts target(s):\n' + StatMultiplierText.multiplier_text_list_to_string(multipliers) + '\n [/center]'
		targetStatChanges.visible = true
	else:
		targetStatChanges.visible = false
		
	if moveEffect.statusEffect != null:
		moveStatusEffect.text = '[center]Applies ' + StatusEffect.potency_to_string(moveEffect.statusEffect.potency) \
				+ ' ' + StatusEffect.status_type_to_string(moveEffect.statusEffect.type) \
				+ ' (' + String.num(roundi(moveEffect.statusChance * 100)) + '% Chance)[/center]'
		moveStatusEffect.visible = true
	else:
		moveStatusEffect.visible = false
	
	if isSurgeEffect and moveEffect.surgeChanges != null:
		surgeChangesDescription.text = '[center]Surge Changes | Per Extra Orb Spent:\n' + moveEffect.surgeChanges.get_description() + '[/center]'
		surgeChangesDescription.visible = true
	else:
		surgeChangesDescription.visible = false

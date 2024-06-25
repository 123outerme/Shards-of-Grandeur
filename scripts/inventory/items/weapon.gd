extends Item
class_name Weapon

@export var statChanges: StatChanges = StatChanges.new()
@export var timing: BattleCommand.ApplyTiming = BattleCommand.ApplyTiming.BEFORE_ROUND
@export var bonusOrbs: int = 0

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.WEAPON,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 1,
	i_usable = false,
	i_battleUsable = false,
	i_consumable = false,
	i_equippable = true,
	i_targets = BattleCommand.Targets.NONE,
	i_statChanges = StatChanges.new(),
	i_timing = BattleCommand.ApplyTiming.BEFORE_ROUND,
	i_bonusOrbs = 0,
):
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	statChanges = i_statChanges
	timing = i_timing
	bonusOrbs = i_bonusOrbs

func get_use_message(_target: Combatant) -> String:
	return ''

func apply_effects(target: Combatant, applyTiming: BattleCommand.ApplyTiming):
	if timing == applyTiming and statChanges != null and statChanges.has_stat_changes():
		target.statChanges.stack(statChanges)

func get_apply_text(target: Combatant, applyTiming: BattleCommand.ApplyTiming) -> String:
	if timing == applyTiming and statChanges != null and statChanges.has_stat_changes():
		var multipliers: Array[StatMultiplierText] = statChanges.get_multipliers_text()
		var prefix: String = ''
		if applyTiming == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG:
			prefix = 'On hit, '
		return prefix + target.disp_name() + ' gains ' + StatMultiplierText.multiplier_text_list_to_string(multipliers) + ' from wielding the ' + itemName + '.'
	return ''

func get_effect_text(inBattle: bool = true) -> String:
	if (statChanges == null or not statChanges.has_stat_changes()) and bonusOrbs == 0:
		return ''
	var effectText: String = 'While Equipped, '
	
	if bonusOrbs > 0:
		effectText += '+' + String.num(bonusOrbs) + ' Orb'
		if bonusOrbs > 1:
			effectText += 's'
		effectText += ' at the start of Battle'
	
	if statChanges != null and statChanges.has_stat_changes():
		if bonusOrbs > 0:
			effectText += ', and '
		var multipliers: Array[StatMultiplierText] = statChanges.get_multipliers_text()
		effectText += BattleCommand.apply_timing_to_string(timing) + ':\n' + StatMultiplierText.multiplier_text_list_to_string(multipliers)
	return effectText

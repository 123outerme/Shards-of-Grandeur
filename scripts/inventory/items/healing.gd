extends Item
class_name Healing

@export_category("Healing")
@export var healBy: int = 50
@export var statusStrengthHeal: StatusEffect.Potency = StatusEffect.Potency.NONE
@export var statChanges: StatChanges = null

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.HEALING,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 0,
	i_usable = true,
	i_battleUsable = true,
	i_consumable = true,
	i_equippable = false,
	i_targets = BattleCommand.Targets.ALLY,
	i_healBy = 50,
	i_statusStrengthHeal = StatusEffect.Potency.NONE,
	i_statChanges = null,
):
	
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	healBy = i_healBy
	statusStrengthHeal = i_statusStrengthHeal
	statChanges = i_statChanges

func use(target: Combatant):
	target.currentHp = min(target.currentHp + healBy, target.stats.maxHp)
	if target.statusEffect != null and target.statusEffect.potency <= statusStrengthHeal:
		target.statusEffect = null
	if statChanges != null:
		target.statChanges.stack(statChanges)

func get_use_message(target: Combatant) -> String:
	return 'Using the ' + itemName + ', ' + target.disp_name() + ' recovers ' + TextUtils.num_to_comma_string(healBy) + ' HP!'

func get_effect_text() -> String:
	var effectText: String = 'Use on a combatant in Battle to '
	var outsideOfBattleText: String = ''
	var effectMsgs: Array[String] = []
	
	if healBy > 0:
		effectMsgs.append('heal by ' + TextUtils.num_to_comma_string(healBy) + ' HP')
		outsideOfBattleText = '\nUse outside of Battle to heal yourself ' + TextUtils.num_to_comma_string(healBy) + ' HP.'
		
	if statusStrengthHeal != StatusEffect.Potency.NONE:
		effectMsgs.append('cure of all ' + StatusEffect.potency_to_string(statusStrengthHeal) + ' status effects')

	if statChanges != null:
		var multipliers: Array[StatMultiplierText] = statChanges.get_multipliers_text()
		effectMsgs.append('boost ' + StatMultiplierText.multiplier_text_list_to_string(multipliers))

	for idx in range(len(effectMsgs)):
		effectText += effectMsgs[idx]
		if idx < len(effectMsgs) - 1:
			if idx < len(effectMsgs) - 2:
				effectText += ', '
			else:
				effectText += ' and '
		else:
			effectText += '.'
	
	if len(effectMsgs) > 1:
		effectText += outsideOfBattleText # also show out-of-battle text (since only healing happens outside of battle)
	
	return effectText

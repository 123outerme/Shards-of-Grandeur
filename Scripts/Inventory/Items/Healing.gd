extends Item
class_name Healing

@export_category("Healing")
@export var healBy: int = 50
@export var statusStrengthHeal: StatusEffect.Potency = StatusEffect.Potency.NONE

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
):
	
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	healBy = i_healBy
	statusStrengthHeal = i_statusStrengthHeal

func use(target: Combatant):
	target.currentHp = min(target.currentHp + healBy, target.stats.maxHp)
	if target.statusEffect != null and target.statusEffect.potency <= statusStrengthHeal:
		target.statusEffect = null

func get_use_message(target: Combatant) -> String:
	var useMessage: String = 'Using the ' + itemName + ', ' + target.disp_name()
	
	if healBy > 0:
		useMessage += ' recovers ' + str(healBy) + 'HP'
	
	var curedOfStatus: bool = statusStrengthHeal != StatusEffect.Potency.NONE
	if healBy > 0 and curedOfStatus:
		useMessage += ' and'
	else:
		useMessage += '.'
	
	if curedOfStatus:
		useMessage += ' is cured of all statuses!'
	
	return useMessage

func get_effect_text() -> String:
	var effectText: String = 'Use in Battle to '
	var outsideOfBattleText: String = ''
	
	if healBy > 0:
		effectText += 'Heal a Combatant by ' + TextUtils.num_to_comma_string(healBy) + ' HP'
		outsideOfBattleText = ', or Use Outside of Battle to Heal Yourself ' + TextUtils.num_to_comma_string(healBy) + ' HP'
	
	var curedOfStatus: bool = statusStrengthHeal != StatusEffect.Potency.NONE
	if curedOfStatus:
		effectText += ' and cure of all ' + StatusEffect.potency_to_string(statusStrengthHeal) + ' status effects'
		
	return effectText + outsideOfBattleText

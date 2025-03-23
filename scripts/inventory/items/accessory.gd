extends Item
class_name Accessory

@export_range(0,10) var bonusOrbs: int = 0

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.ACCESSORY,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 1,
	i_usable = false,
	i_battleUsable = false,
	i_consumable = false,
	i_equippable = true,
	i_targets = BattleCommand.Targets.NONE,
	i_bonusOrbs = 0,
):
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	bonusOrbs = i_bonusOrbs

func get_use_message(_target: Combatant) -> String:
	return ''

func get_effect_text(inBattle: bool = true) -> String:
	if bonusOrbs == 0:
		return ''
	var effectText: String = 'While Equipped, '
	
	effectText += '+' + String.num_int64(bonusOrbs) + ' Orb'
	if bonusOrbs > 1:
		effectText += 's'
	effectText += ' at the start of Battle'
	return effectText

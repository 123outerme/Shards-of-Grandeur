extends Item
class_name Healing

@export_category("Healing")
@export var healBy: int = 50

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
):
	
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	healBy = i_healBy

func use(target: Combatant):
	target.currentHp = min(target.currentHp + healBy, target.stats.maxHp)

extends Item
class_name KeyItem

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.KEY_ITEM,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 0,
	i_usable = true,
	i_battleUsable = false,
	i_consumable = false,
	i_equippable = false,
	i_targets = BattleCommand.Targets.SELF,
):
	super(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable)

func get_use_message(_target: Combatant) -> String:
	return '' # TODO

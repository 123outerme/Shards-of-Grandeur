extends Item
class_name Weapon

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.WEAPON,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 1,
	i_usable = true,
	i_consumable = false,
	i_equippable = true,
):
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_consumable, i_equippable)

extends Item
class_name Shard

@export var combatantSaveName: String = ''

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.SHARD,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 5,
	i_usable = true,
	i_consumable = true,
	i_equippable = false,
):
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_consumable, i_equippable)

func get_combatant() -> Combatant:
	return Combatant.load_combatant_resource(combatantSaveName)

extends Item
class_name KeyItem

@export_multiline var useMessage: String = ''
@export_multiline var effectText: String = ''

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
	i_useMsg = '',
	i_effectText = '',
):
	super(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	useMessage = i_useMsg
	effectText = i_effectText

func get_use_message(_target: Combatant) -> String:
	return useMessage

func get_effect_text() -> String:
	return effectText

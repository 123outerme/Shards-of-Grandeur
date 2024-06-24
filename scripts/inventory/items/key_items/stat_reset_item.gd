extends KeyItem
class_name StatResetItem

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.KEY_ITEM,
	i_itemDescription = "",
	i_cost = 50,
	i_maxCount = 2,
	i_usable = true,
	i_battleUsable = false,
	i_consumable = true,
	i_equippable = false,
	i_targets = BattleCommand.Targets.SELF,
	i_keyItemType = KeyItem.KeyItemType.EXP_ITEM,
	i_useMsg = '',
	i_effectText = '',
):
	super(
		i_sprite,
		i_name,
		i_type,
		i_itemDescription,
		i_cost,
		i_maxCount,
		i_usable,
		i_battleUsable,
		i_consumable,
		i_equippable,
		i_targets,
		i_keyItemType,
		i_useMsg,
		i_effectText)

func use(target: Combatant):
	target.reset_all_evolutions_stat_totals()

func get_use_message(target: Combatant) -> String:
	return target.disp_name() + ' had all allocated Stat Points reset!'

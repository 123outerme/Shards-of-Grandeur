extends KeyItem
class_name ExpItem

@export var experience: int = 50

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
	i_exp = 50,
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
	experience = i_exp

func use(_target: Combatant):
	var lvsGained: int = PlayerResources.playerInfo.combatant.stats.add_exp(experience)
	if lvsGained > 0:
		PlayerFinder.player.level_up(lvsGained)

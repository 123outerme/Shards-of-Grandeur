extends Item
class_name KeyItem

enum KeyItemType {
	STORY_ITEM = 0,
	TELEPORT_STONE = 1,
	EXP_ITEM = 2,
	STAT_RESET_ITEM = 3,
	BATTLE_MODIFIER_ITEM = 4,
}

@export var keyItemType: KeyItemType = KeyItemType.STORY_ITEM
@export_multiline var useMessage: String = ''
@export_multiline var effectText: String = ''

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.KEY_ITEM,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 0,
	i_usable: bool = true,
	i_battleUsable: bool = false,
	i_consumable: bool = false,
	i_equippable: bool = false,
	i_trashable: bool = false,
	i_targets = BattleCommand.Targets.SELF,
	i_keyItemType = KeyItemType.STORY_ITEM,
	i_useMsg = '',
	i_effectText = '',
):
	super(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_trashable, i_targets)
	keyItemType = i_keyItemType
	useMessage = i_useMsg
	effectText = i_effectText

func get_use_message(_target: Combatant) -> String:
	return useMessage

func get_effect_text(inBattle: bool = true) -> String:
	return effectText

func get_as_key_item_type():
	match keyItemType:
		KeyItemType.TELEPORT_STONE:
			return self as TeleportStone
		KeyItemType.EXP_ITEM:
			return self as ExpItem
		KeyItemType.STAT_RESET_ITEM:
			return self as StatResetItem
		KeyItemType.BATTLE_MODIFIER_ITEM:
			return self as BattleModifierItem
	return self

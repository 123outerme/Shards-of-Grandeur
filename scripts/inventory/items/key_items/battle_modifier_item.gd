extends KeyItem
class_name BattleModifierItem

## multiplier to stack item count rewards in RandomEncounters
@export var rewardItemCountModifier: float = 1.0

## multiplier to stack exp rewards in RandomEncounters
@export var rewardExpModifier: float = 1.0

## multiplier to stack gold rewards in RandomEncounters
@export var rewardGoldModifier: float = 1.0

## multiplier to stack minion Attunement rewards in any battle you summon
@export var attunementModifier: float = 1.0

## if true, the next RandomEncounter will automatically spawn 3x the "face" enemy (Center/combatant1), ignoring its allies set in the Encounter
@export var spawnsThreeOfFace: bool = false

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
	i_keyItemType = KeyItem.KeyItemType.BATTLE_MODIFIER_ITEM,
	i_useMsg = '',
	i_effectText = '',
	i_rewardItemCountModifier: float = 1.0,
	i_rewardExpModifier: float = 1.0,
	i_rewardGoldModifier: float = 1.0,
	i_attunementModifier: float = 1.0,
	i_spawnsThreeOfFace: bool = false,
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
	rewardItemCountModifier = i_rewardItemCountModifier
	rewardExpModifier = i_rewardExpModifier
	rewardGoldModifier = i_rewardGoldModifier
	attunementModifier = i_attunementModifier
	spawnsThreeOfFace = i_spawnsThreeOfFace

func can_be_used_now() -> bool:
	return self not in PlayerResources.playerInfo.activeBattleModifierItems

func use(_target: Combatant):
	if can_be_used_now():
		PlayerResources.playerInfo.activeBattleModifierItems.append(self)

func get_use_message(_target: Combatant) -> String:
	var useMessage: String = 'In the next roaming encounter, the following items will be active:\n\n'
	
	var activeModifierItems: Array[BattleModifierItem] = PlayerResources.playerInfo.activeBattleModifierItems.duplicate(false)
	if self not in activeModifierItems:
		activeModifierItems.append(self)
	
	for idx: int in range(len(activeModifierItems)):
		var modifierItem: BattleModifierItem = activeModifierItems[idx]
		useMessage += '* ' + modifierItem.itemName
		if idx < len(activeModifierItems) - 1:
			useMessage += '\n'
	
	return useMessage

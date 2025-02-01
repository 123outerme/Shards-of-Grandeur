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
	var useMsg: String = 'In the next roaming encounter, the following will be active:\n\n'
	
	var activeModifierItems: Array[BattleModifierItem] = PlayerResources.playerInfo.activeBattleModifierItems.duplicate(false)
	if self not in activeModifierItems:
		activeModifierItems.append(self)
	
	for idx: int in range(len(activeModifierItems)):
		var modifierItem: BattleModifierItem = activeModifierItems[idx]
		useMsg += '* ' + modifierItem.itemName + ' (' + TextUtils.string_arr_to_string(modifierItem.get_effect_texts(true)) + ')'
		if idx < len(activeModifierItems) - 1:
			useMsg += '\n'
	
	return useMsg

func get_effect_text(inBattle: bool = true) -> String:
	var effectTexts: Array[String] = get_effect_texts()
	return 'When used outside of Battle, the next Battle will have the following active:\n' \
			+ TextUtils.string_arr_to_string(effectTexts) + '.'

func get_effect_texts(short: bool = false) -> Array[String]:
	var effectTexts: Array[String] = []
	if rewardItemCountModifier != 1.0:
		if rewardItemCountModifier <= 0:
			if short:
				effectTexts.append('No Items')
			else:
				effectTexts.append('No Items will drop')
		else:
			var modifierStr: String = String.num(roundi(rewardItemCountModifier * 100) - 100)
			if rewardItemCountModifier > 1.0:
				modifierStr = '+' + modifierStr
			if short:
				effectTexts.append(modifierStr + '% Items')
			else:
				effectTexts.append(modifierStr + '% Item drops')
	
	if rewardExpModifier != 1.0:
		if rewardExpModifier <= 0:
			if short:
				effectTexts.append('No Exp')
			else:
				effectTexts.append('No Exp. will be gained')
		else:
			var modifierStr: String = String.num(roundi(rewardExpModifier * 100) - 100)
			if rewardExpModifier > 1.0:
				modifierStr = '+' + modifierStr
			if short:
				effectTexts.append(modifierStr + '% Exp')
			else:
				effectTexts.append(modifierStr + '% Exp. awarded')
	
	if rewardGoldModifier != 1.0:
		if rewardGoldModifier <= 0:
			if short:
				effectTexts.append('No Gold')
			else:
				effectTexts.append('No Gold will be gained')
		else:
			var modifierStr: String = String.num(roundi(rewardGoldModifier * 100) - 100)
			if rewardGoldModifier > 1.0:
				modifierStr = '+' + modifierStr
			if short:
				effectTexts.append(modifierStr + '% Gold')
			else:
				effectTexts.append(modifierStr + '% Gold awarded')
	
	if attunementModifier != 1.0:
		if attunementModifier <= 0:
			if short:
				effectTexts.append('No Minion Attunement')
			else:
				effectTexts.append('The summoned minion will not recieve Attunement')
		else:
			var modifierStr: String = String.num(roundi(attunementModifier * 100) - 100)
			if attunementModifier > 1.0:
				modifierStr = '+' + modifierStr
			if short:
				effectTexts.append(modifierStr + '% Attunement')
			else:
				effectTexts.append(modifierStr + '% Attunement for the summoned minion')
	
	if spawnsThreeOfFace:
		if short:
			effectTexts.append('Lures 3x the encountered creature')
		else:
			effectTexts.append('Lures 3 of the encountered creature to the battle')
	
	return effectTexts

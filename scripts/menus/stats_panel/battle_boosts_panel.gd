class_name BattleBoostsPanel
extends Control

@export var inBattle: bool = false
@export var levelUp: bool = false
@export var enabled: bool = true

@onready var battleBoostsText: RichTextLabel = get_node('Panel/BattleBoostsText')

func load_battle_boosts_panel() -> void:
	var itemCountModifier: float = PlayerResources.playerInfo.get_battle_reward_item_count_modifier()
	var expModifier: float = PlayerResources.playerInfo.get_battle_reward_exp_modifier()
	var goldModifier: float = PlayerResources.playerInfo.get_battle_reward_gold_modifier()
	var attunementModifier: float = PlayerResources.playerInfo.get_battle_attunement_modifier()
	var spawnsThreeOfFace: bool = PlayerResources.playerInfo.get_spawns_three_face_combatant()
	
	if not enabled or (inBattle and levelUp) or len(PlayerResources.playerInfo.activeBattleModifierItems) == 0 or \
			(expModifier == 1.0 and goldModifier == 1.0 and attunementModifier == 1.0 and not spawnsThreeOfFace):
		enabled = false
		visible = false
		return
	
	enabled = true
	visible = true
	
	var effectTexts: Array[String] = []
	if spawnsThreeOfFace:
		effectTexts.append('Encountering 3x the roaming creature\n')
	
	if itemCountModifier != 1.0:
		if itemCountModifier <= 0:
			effectTexts.append('No Items will drop')
		else:
			var modifierStr: String = String.num_int64(roundi(itemCountModifier * 100) - 100)
			if itemCountModifier > 1.0:
				modifierStr = '+' + modifierStr
			effectTexts.append(modifierStr + '% Item drops')
	
	if expModifier != 1.0:
		if expModifier <= 0:
			effectTexts.append('No Exp. will be gained')
		else:
			var modifierStr: String = String.num_int64(roundi(expModifier * 100) - 100)
			if expModifier > 1.0:
				modifierStr = '+' + modifierStr
			effectTexts.append(modifierStr + '% Exp. awarded')
	
	if goldModifier != 1.0:
		if goldModifier <= 0:
			effectTexts.append('No Gold will be gained')
		else:
			var modifierStr: String = String.num_int64(roundi(goldModifier * 100) - 100)
			if goldModifier > 1.0:
				modifierStr = '+' + modifierStr
			effectTexts.append(modifierStr + '% Gold awarded')
	
	if attunementModifier != 1.0:
		if attunementModifier <= 0:
				effectTexts.append('The summoned minion will not recieve Attunement')
		else:
			var modifierStr: String = String.num_int64(roundi(attunementModifier * 100) - 100)
			if attunementModifier > 1.0:
				modifierStr = '+' + modifierStr
			effectTexts.append(modifierStr + '% Attunement for the summoned minion')
	
	battleBoostsText.text = '[center]Next Battle:\n\n' + TextUtils.string_arr_to_string(effectTexts, '\n', '\n', '\n', '* ') + '[/center]'

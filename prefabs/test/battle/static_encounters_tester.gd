extends Node

const STATIC_ENCOUNTERS_ROOT_PATH := 'res://gamedata/static_encounters/'

var resultStrings: Array[String] = []

func _ready() -> void:
	execute_for_each_static_encounter(test_reward_exp_versus_loot_table_exp)
	print('------------------')
	execute_for_each_static_encounter(test_reward_gold_versus_loot_table_gold)
	get_tree().quit()

func test_reward_exp_versus_loot_table_exp(staticEncounter: StaticEncounter) -> void:
	if staticEncounter.useStaticRewards:
		var hasSurviveWinConBonusRewards: bool = staticEncounter.winCon is SurviveWinCon and len((staticEncounter.winCon as SurviveWinCon).staticTotalDefeatRewards) > 0
		if len(staticEncounter.rewards) > 0 or hasSurviveWinConBonusRewards:
			var combatants: Array[Combatant] = [staticEncounter.combatant1, staticEncounter.combatant2, staticEncounter.combatant3]
			var combatantLvs: Array[int] = [staticEncounter.combatant1Level, staticEncounter.combatant2Level, staticEncounter.combatant3Level]
			resultStrings.append('Static encounter ' + staticEncounter.resource_path + ' exp rewards vs combatants\' loot table exp rewards:')
			for idx: int in range(len(staticEncounter.rewards)):
				var combatant: Combatant = combatants[idx]
				var combatantLv: int = combatantLvs[idx]
				var staticReward: Reward = staticEncounter.rewards[idx]
				var avgLootTableRewardExp: float = 0
				if combatant.dropTable != null:
					for weightedReward: WeightedReward in combatant.dropTable.weightedRewards:
						# assuming player lv == enemy lv
						var scaledUpReward: Reward = weightedReward.reward.scale_reward_by_level(1, combatantLv, combatantLv)
						avgLootTableRewardExp += scaledUpReward.experience
					avgLootTableRewardExp /= len(combatant.dropTable.weightedRewards)
				resultStrings.append('> Combatant ' + String.num_int64(idx + 1) + ': Static reward exp = ' + String.num_int64(staticReward.experience) + ' / Avg loot table rewards exp = ' + String.num(avgLootTableRewardExp))
			if hasSurviveWinConBonusRewards:
				var surviveWinCon: SurviveWinCon = staticEncounter.winCon as SurviveWinCon
				for idx: int in range(len(surviveWinCon.staticTotalDefeatRewards)):
					var combatant: Combatant = combatants[idx]
					var combatantLv: int = combatantLvs[idx]
					var staticReward: Reward = surviveWinCon.staticTotalDefeatRewards[idx]
					var avgLootTableRewardExp: float = 0
					if combatant.dropTable != null:
						for weightedReward: WeightedReward in combatant.dropTable.weightedRewards:
							# assuming player lv == enemy lv
							var scaledUpReward: Reward = weightedReward.reward.scale_reward_by_level(1, combatantLv, combatantLv)
							avgLootTableRewardExp += scaledUpReward.experience
						avgLootTableRewardExp /= len(combatant.dropTable.weightedRewards)
					resultStrings.append('> Combatant ' + String.num_int64(idx + 1) + ': Static SurviveWinCon "total defeat" reward exp = ' + String.num_int64(staticReward.experience) + ' / Avg loot table rewards exp = ' + String.num(avgLootTableRewardExp))
		else:
			resultStrings.append('Static encounter ' + staticEncounter.resource_path + ' explicitly gives 0 rewards')

func test_reward_gold_versus_loot_table_gold(staticEncounter: StaticEncounter) -> void:
	if staticEncounter.useStaticRewards:
		var hasSurviveWinConBonusRewards: bool = staticEncounter.winCon is SurviveWinCon and len((staticEncounter.winCon as SurviveWinCon).staticTotalDefeatRewards) > 0
		if len(staticEncounter.rewards) > 0 or hasSurviveWinConBonusRewards:
			var combatants: Array[Combatant] = [staticEncounter.combatant1, staticEncounter.combatant2, staticEncounter.combatant3]
			var combatantLvs: Array[int] = [staticEncounter.combatant1Level, staticEncounter.combatant2Level, staticEncounter.combatant3Level]
			resultStrings.append('Static encounter ' + staticEncounter.resource_path + ' gold rewards vs combatants\' loot table gold rewards:')
			for idx: int in range(len(staticEncounter.rewards)):
				var combatant: Combatant = combatants[idx]
				var combatantLv: int = combatantLvs[idx]
				var staticReward: Reward = staticEncounter.rewards[idx]
				var avgLootTableRewardGold: float = 0
				if combatant.dropTable != null:
					for weightedReward: WeightedReward in combatant.dropTable.weightedRewards:
						# assuming player lv == enemy lv
						var scaledUpReward: Reward = weightedReward.reward.scale_reward_by_level(1, combatantLv, combatantLv)
						avgLootTableRewardGold += scaledUpReward.gold
					avgLootTableRewardGold /= len(combatant.dropTable.weightedRewards)
				resultStrings.append('> Combatant ' + String.num_int64(idx + 1) + ': Static reward gold = ' + String.num_int64(staticReward.gold) + ' / Avg loot table rewards gold = ' + String.num(avgLootTableRewardGold))
			if hasSurviveWinConBonusRewards:
				var surviveWinCon: SurviveWinCon = staticEncounter.winCon as SurviveWinCon
				for idx: int in range(len(surviveWinCon.staticTotalDefeatRewards)):
					var combatant: Combatant = combatants[idx]
					var combatantLv: int = combatantLvs[idx]
					var staticReward: Reward = surviveWinCon.staticTotalDefeatRewards[idx]
					var avgLootTableRewardGold: float = 0
					if combatant.dropTable != null:
						for weightedReward: WeightedReward in combatant.dropTable.weightedRewards:
							# assuming player lv == enemy lv
							var scaledUpReward: Reward = weightedReward.reward.scale_reward_by_level(1, combatantLv, combatantLv)
							avgLootTableRewardGold += scaledUpReward.gold
						avgLootTableRewardGold /= len(combatant.dropTable.weightedRewards)
					resultStrings.append('> Combatant ' + String.num_int64(idx + 1) + ': SurviveWinCon "total defeat" reward gold = ' + String.num_int64(staticReward.gold) + ' / Avg loot table rewards gold = ' + String.num(avgLootTableRewardGold))
		else:
			resultStrings.append('Static encounter ' + staticEncounter.resource_path + ' explicitly gives 0 rewards')

# execute helper methods
func execute_for_each_static_encounter(callable: Callable) -> void:
	resultStrings = []
	_execute_for_each_static_encounter_helper(STATIC_ENCOUNTERS_ROOT_PATH, callable)
	for strng: String in resultStrings:
		print(strng)
	
func _execute_for_each_static_encounter_helper(path: String, callable: Callable) -> void:
	var files: PackedStringArray = DirAccess.get_files_at(path)
	for file: String in files:
			# just in case there's a ".remap" in the path that's not at the end (although this should never be the case):
			# get everything except the LAST file extension present
			var resourceFilename: String = file.get_basename()
				# if it doesn't have ".tres" at the end (only if being played in the editor): add it
			if not resourceFilename.ends_with('.tres'):
				resourceFilename += '.tres'
			var staticEncounter = ResourceLoader.load(path + resourceFilename)
			if staticEncounter != null and staticEncounter is StaticEncounter:
				callable.call(staticEncounter)
	var directories: PackedStringArray = DirAccess.get_directories_at(path)
	for dir: String in directories:
		_execute_for_each_static_encounter_helper(path + '/' + dir + '/', callable)

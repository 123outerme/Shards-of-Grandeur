extends EnemyEncounter
class_name RandomEncounter

@export var combatantsMinLevel: int = 1
@export var combatantsMaxLevel: int = 1
@export var combatantsLvToPlayerLvRatio: float = 1
@export var levelStages: Array[RandomEncounterLevelStage] = []
@export var combatant1Equipment: CombatantEquipment = null
@export var combatant1Rewards: CombatantRewards = null
@export var combatant2Options: Array[WeightedCombatant] = []
@export var combatant3Options: Array[WeightedCombatant] = []

func _init(
	i_combatant1 = null,
	i_combatant1Weapon: Weapon = null,
	i_combatant1Armor: Armor = null,
	i_combatant1Accessory: Accessory = null,
	i_combatant1StatAllocStrat: StatAllocationStrategy = null,
	i_specialRules = SpecialRules.NONE,
	i_winCon = null,
	i_customWinText = '',
	i_minLevel = 1,
	i_maxLevel = 1,
	i_levelRatio = 1,
	i_levelStages: Array[RandomEncounterLevelStage] = [],
	i_combatant1Equipment = null,
	i_combatant1Rewards = null,
	i_combatant2Options: Array[WeightedCombatant] = [],
	i_combatant3Options: Array[WeightedCombatant] = [],
):
	super(i_combatant1, i_combatant1Weapon, i_combatant1Armor, i_combatant1Accessory, i_combatant1StatAllocStrat, i_specialRules, i_winCon, i_customWinText)
	combatantsMinLevel = i_minLevel
	combatantsMaxLevel = i_maxLevel
	combatantsLvToPlayerLvRatio = i_levelRatio
	levelStages = i_levelStages
	combatant1Equipment = i_combatant1Equipment
	combatant1Rewards = i_combatant1Rewards
	combatant2Options = i_combatant2Options
	combatant3Options = i_combatant3Options
	
func get_combatant_level() -> int:
	'''
	var lvDiffScaled: float = (PlayerResources.playerInfo.combatant.stats.level - combatantsMinLevel) * combatantsLvToPlayerLvRatio
	lvDiffScaled = floori(lvDiffScaled + randf_range(0, 0.99))
	# scaled level difference = floor( (playerlv - min) * ratio + X ), where X in [0, 1)
	var level: int = min(combatantsMaxLevel, \
		max(combatantsMinLevel, combatantsMinLevel + lvDiffScaled))
	'''
	# /level = min + scaled lvdiff, bounded between min and max lv
	
	var minLv: int = combatantsMinLevel
	var maxLv: int = combatantsMaxLevel
	
	for stage: RandomEncounterLevelStage in levelStages:
		if stage.is_valid():
			minLv = stage.minLevel
			maxLv = stage.maxLevel
			break
	
	var level: int = roundi(randf_range(minLv, maxLv))
	return level

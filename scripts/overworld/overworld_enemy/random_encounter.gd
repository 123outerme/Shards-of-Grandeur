extends EnemyEncounter
class_name RandomEncounter

@export var combatantsMinLevel: int = 1
@export var combatantsMaxLevel: int = 1
@export var combatantsLvToPlayerLvRatio: float = 1
@export var combatant1Rewards: Array[WeightedReward] = []
@export var combatant2Options: Array[WeightedCombatant] = []
@export var combatant2Rewards: Array[WeightedReward] = []
@export var combatant3Options: Array[WeightedCombatant] = []
@export var combatant3Rewards: Array[WeightedReward] = []

func _init(
	i_combatant1 = null,
	i_minLevel = 1,
	i_maxLevel = 1,
	i_levelRatio = 1,
	i_combatant1Rewards: Array[WeightedReward] = [],
	i_combatant2Options: Array[WeightedCombatant] = [],
	i_combatant2Rewards: Array[WeightedReward] = [],
	i_combatant3Options: Array[WeightedCombatant] = [],
	i_combatant3Rewards: Array[WeightedReward] = [],
):
	super(i_combatant1)
	combatantsMinLevel = i_minLevel
	combatantsMaxLevel = i_maxLevel
	combatantsLvToPlayerLvRatio = i_levelRatio
	combatant1Rewards = i_combatant1Rewards
	combatant2Options = i_combatant2Options
	combatant2Rewards = i_combatant2Rewards
	combatant3Options = i_combatant3Options
	combatant3Rewards = i_combatant3Rewards
	
func get_combatant_level() -> int:
	var lvDiffScaled: float = (PlayerResources.playerInfo.combatant.stats.level - combatantsMinLevel) * combatantsLvToPlayerLvRatio
	lvDiffScaled = floori(lvDiffScaled + randf_range(0, 0.99))
	# scaled level difference = floor( (playerlv - min) * ratio + X ), where X in [0, 1)
	var level: int = min(combatantsMaxLevel, \
		max(combatantsMinLevel, combatantsMinLevel + lvDiffScaled))
	# level = min + scaled lvdiff, bounded between min and max lv
	return level
